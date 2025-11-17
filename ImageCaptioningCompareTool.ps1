# Resizable PowerShell Image Captioning Tool with Comparison Feature

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create the main form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Image Captioning Tool with Comparison"
$form.Size = New-Object System.Drawing.Size(800, 800)
$form.StartPosition = "CenterScreen"
$form.KeyPreview = $true
$form.MinimumSize = New-Object System.Drawing.Size(600, 600)

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
$statusLabel.Text = "Ready - Press 'Open Image Folder' to begin"
$statusLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$statusLabel.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
$statusLabel.Anchor = [System.Windows.Forms.AnchorStyles]::Left -bor
                      [System.Windows.Forms.AnchorStyles]::Right -bor
                      [System.Windows.Forms.AnchorStyles]::Bottom
$form.Controls.Add($statusLabel)

# Create label for main caption box
$mainCaptionLabel = New-Object System.Windows.Forms.Label
$mainCaptionLabel.Text = "Main Caption:"
$mainCaptionLabel.Height = 20
$mainCaptionLabel.Anchor = [System.Windows.Forms.AnchorStyles]::Left -bor
                           [System.Windows.Forms.AnchorStyles]::Right -bor
                           [System.Windows.Forms.AnchorStyles]::Bottom
$form.Controls.Add($mainCaptionLabel)

# Create TextBox for main captions
$captionBox = New-Object System.Windows.Forms.TextBox
$captionBox.Multiline = $true
$captionBox.ScrollBars = [System.Windows.Forms.ScrollBars]::Vertical
$captionBox.Anchor = [System.Windows.Forms.AnchorStyles]::Left -bor
                     [System.Windows.Forms.AnchorStyles]::Right -bor
                     [System.Windows.Forms.AnchorStyles]::Bottom
$form.Controls.Add($captionBox)

# Create label for comparison caption box
$comparisonCaptionLabel = New-Object System.Windows.Forms.Label
$comparisonCaptionLabel.Text = "Comparison Caption (Editable):"
$comparisonCaptionLabel.Height = 20
$comparisonCaptionLabel.Anchor = [System.Windows.Forms.AnchorStyles]::Left -bor
                                 [System.Windows.Forms.AnchorStyles]::Right -bor
                                 [System.Windows.Forms.AnchorStyles]::Bottom
$form.Controls.Add($comparisonCaptionLabel)

# Create TextBox for comparison captions (EDITABLE)
$comparisonBox = New-Object System.Windows.Forms.TextBox
$comparisonBox.Multiline = $true
$comparisonBox.ScrollBars = [System.Windows.Forms.ScrollBars]::Vertical
$comparisonBox.ReadOnly = $false  # Make it editable
$comparisonBox.BackColor = [System.Drawing.SystemColors]::Window  # Normal white background
$comparisonBox.Anchor = [System.Windows.Forms.AnchorStyles]::Left -bor
                        [System.Windows.Forms.AnchorStyles]::Right -bor
                        [System.Windows.Forms.AnchorStyles]::Bottom
$form.Controls.Add($comparisonBox)

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

# Open image folder button
$openButton = New-Object System.Windows.Forms.Button
$openButton.Text = "Open Image Folder"
$openButton.Size = New-Object System.Drawing.Size(130, $CONTROL_HEIGHT)
$openButton.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom
$form.Controls.Add($openButton)

# Open comparison folder button
$openComparisonButton = New-Object System.Windows.Forms.Button
$openComparisonButton.Text = "Open Comparison"
$openComparisonButton.Size = New-Object System.Drawing.Size(130, $CONTROL_HEIGHT)
$openComparisonButton.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom
$form.Controls.Add($openComparisonButton)

# Help text
$helpLabel = New-Object System.Windows.Forms.Label
$helpLabel.Height = $CONTROL_HEIGHT - 10
$helpLabel.Text = "Use left/right arrow keys to navigate (when not typing), ESC to exit. Empty main captions won't be saved."
$helpLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$helpLabel.Anchor = [System.Windows.Forms.AnchorStyles]::Left -bor
                    [System.Windows.Forms.AnchorStyles]::Right -bor
                    [System.Windows.Forms.AnchorStyles]::Bottom
$form.Controls.Add($helpLabel)

# Variables to track current state
$script:currentIndex = 0
$script:imageFiles = @()
$script:currentDirectory = ""
$script:comparisonDirectory = ""

# Variables to track original caption content for change detection
$script:originalMainCaption = ""
$script:originalComparisonCaption = ""

# Function to save the main caption - only if not empty AND modified
function Save-Caption {
    if ($script:imageFiles.Count -eq 0 -or $script:currentIndex -lt 0 -or $script:currentIndex -ge $script:imageFiles.Count) {
        return
    }

    $currentImagePath = $script:imageFiles[$script:currentIndex]
    $captionText = $captionBox.Text.Trim()
    $captionFilePath = "$($currentImagePath).txt"

    # Check if the caption has been modified
    if ($captionText -ne $script:originalMainCaption) {
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

        # Update the original caption to the new value
        $script:originalMainCaption = $captionText
    }
    # If caption hasn't been modified, don't save (preserves file timestamps)
}

# Function to save the comparison caption - only if modified
function Save-ComparisonCaption {
    if ($script:imageFiles.Count -eq 0 -or $script:currentIndex -lt 0 -or $script:currentIndex -ge $script:imageFiles.Count -or $script:comparisonDirectory -eq "") {
        return
    }

    $currentImagePath = $script:imageFiles[$script:currentIndex]
    $filename = Split-Path -Path $currentImagePath -Leaf
    $comparisonText = $comparisonBox.Text.Trim()
    $comparisonFilePath = Join-Path $script:comparisonDirectory "$filename.txt"

    # Check if the comparison caption has been modified
    if ($comparisonText -ne $script:originalComparisonCaption) {
        # Only save if comparison caption is not empty
        if ($comparisonText -ne "") {
            try {
                $comparisonText | Out-File -FilePath $comparisonFilePath -Encoding UTF8 -Force
            } catch {
                [System.Windows.Forms.MessageBox]::Show("Error saving comparison caption: $_", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
            }
        }
        # Note: We don't delete comparison files when empty to preserve original data

        # Update the original comparison caption to the new value
        $script:originalComparisonCaption = $comparisonText
    }
    # If comparison caption hasn't been modified, don't save (preserves file timestamps)
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

# Function to load comparison folder
function Load-ComparisonFolder {
    $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
    $folderBrowser.Description = "Select folder containing comparison caption files"

    if ($folderBrowser.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $script:comparisonDirectory = $folderBrowser.SelectedPath
        $comparisonCaptionLabel.Text = "Comparison Caption ($($script:comparisonDirectory | Split-Path -Leaf)):"

        # Refresh current image to load comparison caption
        Show-CurrentImage
    }
}

# Function to display the current image and load any existing captions
function Show-CurrentImage {
    if ($script:imageFiles.Count -eq 0) {
        $pictureBox.Image = $null
        $captionBox.Text = ""
        $comparisonBox.Text = ""
        $script:originalMainCaption = ""
        $script:originalComparisonCaption = ""
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

        # Load main caption if exists
        $captionFilePath = "$($currentImagePath).txt"
        if (Test-Path $captionFilePath) {
            $captionText = (Get-Content -Path $captionFilePath -Raw).Trim()
            $captionBox.Text = $captionText
            $script:originalMainCaption = $captionText
        } else {
            $captionBox.Text = ""
            $script:originalMainCaption = ""
        }

        # Load comparison caption if comparison directory is set
        if ($script:comparisonDirectory -ne "") {
            # Match based on the main caption filename (imagename.ext.txt)
            $mainCaptionFileName = "$filename.txt"
            $comparisonFilePath = Join-Path $script:comparisonDirectory $mainCaptionFileName

            if (Test-Path $comparisonFilePath) {
                $comparisonText = (Get-Content -Path $comparisonFilePath -Raw).Trim()
                $comparisonBox.Text = $comparisonText
                $script:originalComparisonCaption = $comparisonText
            } else {
                $comparisonBox.Text = ""
                $script:originalComparisonCaption = ""
            }
        } else {
            $comparisonBox.Text = ""
            $script:originalComparisonCaption = ""
        }

    } catch {
        $pictureBox.Image = $null
        $captionBox.Text = ""
        $comparisonBox.Text = ""
        $script:originalMainCaption = ""
        $script:originalComparisonCaption = ""
        $statusLabel.Text = "Error loading image"
        [System.Windows.Forms.MessageBox]::Show("Error displaying image: $_", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
}

# Function to navigate to the previous image
function Show-PreviousImage {
    if ($script:imageFiles.Count -eq 0) {
        return
    }

    # Save both captions before navigating (only if modified)
    Save-Caption
    Save-ComparisonCaption

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

    # Save both captions before navigating (only if modified)
    Save-Caption
    Save-ComparisonCaption

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

    # Position open buttons in the middle
    $buttonSpacing = 10
    $totalButtonWidth = $openButton.Width + $buttonSpacing + $openComparisonButton.Width
    $buttonsStartX = ($form.ClientSize.Width - $totalButtonWidth) / 2

    $openButton.Top = $navButtonsY
    $openButton.Left = $buttonsStartX

    $openComparisonButton.Top = $navButtonsY
    $openComparisonButton.Left = $buttonsStartX + $openButton.Width + $buttonSpacing

    # Position comparison caption box above buttons
    $comparisonBox.Height = 50
    $comparisonBox.Left = $PADDING
    $comparisonBox.Width = $form.ClientSize.Width - ($PADDING * 2)
    $comparisonBox.Top = $navButtonsY - $comparisonBox.Height - 10

    # Position comparison label above comparison box
    $comparisonCaptionLabel.Left = $PADDING
    $comparisonCaptionLabel.Width = $form.ClientSize.Width - ($PADDING * 2)
    $comparisonCaptionLabel.Top = $comparisonBox.Top - $comparisonCaptionLabel.Height - 5

    # Position main caption box above comparison label
    $captionBox.Height = 50
    $captionBox.Left = $PADDING
    $captionBox.Width = $form.ClientSize.Width - ($PADDING * 2)
    $captionBox.Top = $comparisonCaptionLabel.Top - $captionBox.Height - 10

    # Position main caption label above main caption box
    $mainCaptionLabel.Left = $PADDING
    $mainCaptionLabel.Width = $form.ClientSize.Width - ($PADDING * 2)
    $mainCaptionLabel.Top = $captionBox.Top - $mainCaptionLabel.Height - 5

    # Position status label above main caption label
    $statusLabel.Left = $PADDING
    $statusLabel.Width = $form.ClientSize.Width - ($PADDING * 2)
    $statusLabel.Top = $mainCaptionLabel.Top - $statusLabel.Height - 5

    # Size picture box to fill the remaining space
    $pictureBox.Left = $PADDING
    $pictureBox.Top = $PADDING
    $pictureBox.Width = $form.ClientSize.Width - ($PADDING * 2)
    $pictureBox.Height = $statusLabel.Top - $PADDING - 5
}

# Add event handlers for buttons
$openButton.Add_Click({ Load-Images })
$openComparisonButton.Add_Click({ Load-ComparisonFolder })
$prevButton.Add_Click({ Show-PreviousImage })
$nextButton.Add_Click({ Show-NextImage })

# Handle form resizing
$form.Add_Resize({
    Update-ControlPositions
})

# Only use arrow keys for navigation when caption boxes do NOT have focus
$form.Add_KeyDown({
    param($sender, $e)

    # Only process arrow keys if neither caption box has focus
    if ($form.ActiveControl -ne $captionBox -and $form.ActiveControl -ne $comparisonBox) {
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

# Handle form closing to save current captions (only if modified)
$form.Add_FormClosing({
    param($sender, $e)
    Save-Caption
    Save-ComparisonCaption
    if ($pictureBox.Image -ne $null) {
        $pictureBox.Image.Dispose()
    }
})

# Set initial positions
Update-ControlPositions

# Show the form
[void] $form.ShowDialog()