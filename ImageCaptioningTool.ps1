# Resizable PowerShell Image Captioning Tool

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create the main form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Image Captioning Tool"
$form.Size = New-Object System.Drawing.Size(800, 700)
$form.StartPosition = "CenterScreen"
$form.KeyPreview = $true
$form.MinimumSize = New-Object System.Drawing.Size(600, 500) # Set minimum size

# Define padding constants for layout
$PADDING = 20
$CONTROL_HEIGHT = 30
$BUTTON_WIDTH = 120

# Create a PictureBox for displaying images
$pictureBox = New-Object System.Windows.Forms.PictureBox
$pictureBox.Location = New-Object System.Drawing.Point($PADDING, $PADDING)
$pictureBox.SizeMode = [System.Windows.Forms.PictureBoxSizeMode]::Zoom
$pictureBox.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
$pictureBox.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor 
                     [System.Windows.Forms.AnchorStyles]::Left -bor
                     [System.Windows.Forms.AnchorStyles]::Right -bor
                     [System.Windows.Forms.AnchorStyles]::Bottom
$form.Controls.Add($pictureBox)

# Create status label
$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Height = $CONTROL_HEIGHT
$statusLabel.Text = "Ready - Press 'Open Folder' to begin"
$statusLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$statusLabel.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
$statusLabel.Anchor = [System.Windows.Forms.AnchorStyles]::Left -bor 
                      [System.Windows.Forms.AnchorStyles]::Right -bor
                      [System.Windows.Forms.AnchorStyles]::Bottom
$form.Controls.Add($statusLabel)

# Create TextBox for captions
$captionBox = New-Object System.Windows.Forms.TextBox
$captionBox.Multiline = $true
$captionBox.ScrollBars = [System.Windows.Forms.ScrollBars]::Vertical
$captionBox.Anchor = [System.Windows.Forms.AnchorStyles]::Left -bor 
                     [System.Windows.Forms.AnchorStyles]::Right -bor
                     [System.Windows.Forms.AnchorStyles]::Bottom
$form.Controls.Add($captionBox)

# Create navigation buttons
$prevButton = New-Object System.Windows.Forms.Button
$prevButton.Text = "< Previous"
$prevButton.Size = New-Object System.Drawing.Size($BUTTON_WIDTH, $CONTROL_HEIGHT)
$prevButton.Anchor = [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Bottom
$form.Controls.Add($prevButton)

$nextButton = New-Object System.Windows.Forms.Button
$nextButton.Text = "Next >"
$nextButton.Size = New-Object System.Drawing.Size($BUTTON_WIDTH, $CONTROL_HEIGHT)
$nextButton.Anchor = [System.Windows.Forms.AnchorStyles]::Right -bor [System.Windows.Forms.AnchorStyles]::Bottom
$form.Controls.Add($nextButton)

# Open folder button
$openButton = New-Object System.Windows.Forms.Button
$openButton.Text = "Open Folder"
$openButton.Size = New-Object System.Drawing.Size(120, $CONTROL_HEIGHT)
$openButton.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom
$form.Controls.Add($openButton)

# Help text
$helpLabel = New-Object System.Windows.Forms.Label
$helpLabel.Height = $CONTROL_HEIGHT - 10
$helpLabel.Text = "Use left/right arrow keys to navigate UI (when not typing), ESC to exit. Empty captions won't be saved."
$helpLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$helpLabel.Anchor = [System.Windows.Forms.AnchorStyles]::Left -bor 
                    [System.Windows.Forms.AnchorStyles]::Right -bor
                    [System.Windows.Forms.AnchorStyles]::Bottom
$form.Controls.Add($helpLabel)

# Variables to track current state
$script:currentIndex = 0
$script:imageFiles = @()
$script:currentDirectory = ""

# Function to save the caption - only if not empty
function Save-Caption {
    if ($script:imageFiles.Count -eq 0 -or $script:currentIndex -lt 0 -or $script:currentIndex -ge $script:imageFiles.Count) {
        return
    }

    $currentImagePath = $script:imageFiles[$script:currentIndex]
    $captionText = $captionBox.Text.Trim()
    $captionFilePath = "$($currentImagePath).txt"
    
    # Only save if caption is not empty
    if ($captionText -ne "") {
        try {
            $captionText | Out-File -FilePath $captionFilePath -Encoding UTF8
            $statusLabel.Text = "Caption saved for $($currentImagePath | Split-Path -Leaf)"
        } catch {
            [System.Windows.Forms.MessageBox]::Show("Error saving caption: $_", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        }
    } else {
        # If caption file exists but caption is now empty, delete the file
        if (Test-Path $captionFilePath) {
            try {
                Remove-Item -Path $captionFilePath -Force
                $statusLabel.Text = "Empty caption - removed caption file for $($currentImagePath | Split-Path -Leaf)"
            } catch {
                [System.Windows.Forms.MessageBox]::Show("Error removing empty caption file: $_", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
            }
        } else {
            $statusLabel.Text = "Empty caption - no file created for $($currentImagePath | Split-Path -Leaf)"
        }
    }
}

# Function to load images from a directory
function Load-Images {
    $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
    $folderBrowser.Description = "Select folder containing images"
    
    if ($folderBrowser.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $script:currentDirectory = $folderBrowser.SelectedPath
        
        # Use case-insensitive search
        $script:imageFiles = Get-ChildItem -Path $script:currentDirectory -File | 
            Where-Object { $_.Extension -match '\.(jpg|jpeg|png|gif|bmp)$' -or 
                          $_.Extension -match '\.(JPG|JPEG|PNG|GIF|BMP)$' } |
            Sort-Object Name |
            Select-Object -ExpandProperty FullName
        
        if ($script:imageFiles.Count -eq 0) {
            [System.Windows.Forms.MessageBox]::Show("No image files found in selected directory. Please make sure the folder contains .jpg, .jpeg, .png, .gif, or .bmp files.", "No Images", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
            return
        }
        
        $script:currentIndex = 0
        Show-CurrentImage
    }
}

# Function to display the current image and load any existing caption
function Show-CurrentImage {
    if ($script:imageFiles.Count -eq 0) {
        $pictureBox.Image = $null
        $captionBox.Text = ""
        $statusLabel.Text = "No images loaded"
        return
    }
    
    if ($script:currentIndex -lt 0 -or $script:currentIndex -ge $script:imageFiles.Count) {
        return
    }
    
    $currentImagePath = $script:imageFiles[$script:currentIndex]
    
    # Clean up previous image if exists
    if ($pictureBox.Image -ne $null) {
        $oldImage = $pictureBox.Image
        $pictureBox.Image = $null
        $oldImage.Dispose()
    }
    
    try {
        # Load new image
        $pictureBox.Image = [System.Drawing.Image]::FromFile($currentImagePath)
        
        # Update status
        $filename = Split-Path -Path $currentImagePath -Leaf
        $statusLabel.Text = "Image $($script:currentIndex + 1) of $($script:imageFiles.Count): $filename"
        
        # Load caption if exists
        $captionFilePath = "$($currentImagePath).txt"
        if (Test-Path $captionFilePath) {
            $captionBox.Text = (Get-Content -Path $captionFilePath -Raw).Trim()
        } else {
            $captionBox.Text = ""
        }
    } catch {
        $pictureBox.Image = $null
        $captionBox.Text = ""
        $statusLabel.Text = "Error loading image"
        [System.Windows.Forms.MessageBox]::Show("Error displaying image: $_", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
}

# Function to navigate to the previous image
function Show-PreviousImage {
    if ($script:imageFiles.Count -eq 0) {
        return
    }
    
    # Save current caption if not empty
    Save-Caption
    
    # Go to previous image
    $script:currentIndex--
    if ($script:currentIndex -lt 0) {
        $script:currentIndex = $script:imageFiles.Count - 1
    }
    
    Show-CurrentImage
}

# Function to navigate to the next image
function Show-NextImage {
    if ($script:imageFiles.Count -eq 0) {
        return
    }
    
    # Save current caption if not empty
    Save-Caption
    
    # Go to next image
    $script:currentIndex++
    if ($script:currentIndex -ge $script:imageFiles.Count) {
        $script:currentIndex = 0
    }
    
    Show-CurrentImage
}

# Function to update control positions when the form is resized
function Update-ControlPositions {
    # Positioning from bottom
    $bottomMargin = $PADDING
    
    # Position help label at the bottom
    $helpLabel.Width = $form.ClientSize.Width - ($PADDING * 2)
    $helpLabel.Left = $PADDING
    $helpLabel.Top = $form.ClientSize.Height - $helpLabel.Height - $bottomMargin
    
    # Position navigation buttons above help label
    $navButtonsY = $helpLabel.Top - $CONTROL_HEIGHT - 10
    
    $prevButton.Top = $navButtonsY
    $prevButton.Left = $PADDING
    
    $nextButton.Top = $navButtonsY
    $nextButton.Left = $form.ClientSize.Width - $PADDING - $nextButton.Width
    
    # Position open button in the middle
    $openButton.Top = $navButtonsY
    $openButton.Left = ($form.ClientSize.Width - $openButton.Width) / 2
    
    # Position caption box above buttons
    $captionBox.Height = 60
    $captionBox.Left = $PADDING
    $captionBox.Width = $form.ClientSize.Width - ($PADDING * 2)
    $captionBox.Top = $navButtonsY - $captionBox.Height - 10
    
    # Position status label above caption box
    $statusLabel.Left = $PADDING
    $statusLabel.Width = $form.ClientSize.Width - ($PADDING * 2)
    $statusLabel.Top = $captionBox.Top - $statusLabel.Height - 5
    
    # Size picture box to fill the remaining space
    $pictureBox.Left = $PADDING
    $pictureBox.Top = $PADDING
    $pictureBox.Width = $form.ClientSize.Width - ($PADDING * 2)
    $pictureBox.Height = $statusLabel.Top - $PADDING - 5
}

# Add event handlers for buttons
$openButton.Add_Click({ Load-Images })
$prevButton.Add_Click({ Show-PreviousImage })
$nextButton.Add_Click({ Show-NextImage })

# Handle form resizing
$form.Add_Resize({
    Update-ControlPositions
})

# Only use arrow keys for navigation when caption box does NOT have focus
$form.Add_KeyDown({
    param($sender, $e)
    
    # Only process arrow keys if caption box doesn't have focus
    if ($form.ActiveControl -ne $captionBox) {
        switch ($e.KeyCode) {
            # Navigation with arrow keys
            "Left" { 
                Show-PreviousImage
                $e.Handled = $true
            }
            "Right" { 
                Show-NextImage
                $e.Handled = $true
            }
        }
    }
    
    # Escape key always exits
    if ($e.KeyCode -eq [System.Windows.Forms.Keys]::Escape) {
        $form.Close()
    }
})

# Handle form closing to save current caption if not empty
$form.Add_FormClosing({
    param($sender, $e)
    Save-Caption
    if ($pictureBox.Image -ne $null) {
        $pictureBox.Image.Dispose()
    }
})

# Set initial positions
Update-ControlPositions

# Show the form
[void] $form.ShowDialog()
