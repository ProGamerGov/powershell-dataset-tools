# Resizable PowerShell Image Sorting Tool

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create the main form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Image Sorting Tool"
$form.Size = New-Object System.Drawing.Size(800, 700)
$form.StartPosition = "CenterScreen"
$form.KeyPreview = $true  # Important: Make sure this is set to true for key events to work
$form.MinimumSize = New-Object System.Drawing.Size(600, 500) # Set minimum size

# Define padding constants for layout
$PADDING = 20
$CONTROL_HEIGHT = 30
$BUTTON_WIDTH = 120
$BUTTONS_ROW_SPACING = 10

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

# Create status label - will be positioned just below the PictureBox
$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Height = $CONTROL_HEIGHT
$statusLabel.Text = "Ready - Press 'Open Folder' to begin"
$statusLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$statusLabel.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
$statusLabel.Anchor = [System.Windows.Forms.AnchorStyles]::Left -bor 
                      [System.Windows.Forms.AnchorStyles]::Right -bor
                      [System.Windows.Forms.AnchorStyles]::Bottom
$form.Controls.Add($statusLabel)

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

# Create category buttons (avoiding array multiplication)
$button1 = New-Object System.Windows.Forms.Button
$button1.Text = "1: Category 1"
$button1.Size = New-Object System.Drawing.Size($BUTTON_WIDTH, $CONTROL_HEIGHT)
$button1.Tag = 1
$button1.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom
$form.Controls.Add($button1)

$button2 = New-Object System.Windows.Forms.Button
$button2.Text = "2: Category 2"
$button2.Size = New-Object System.Drawing.Size($BUTTON_WIDTH, $CONTROL_HEIGHT)
$button2.Tag = 2
$button2.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom
$form.Controls.Add($button2)

$button3 = New-Object System.Windows.Forms.Button
$button3.Text = "3: Category 3"
$button3.Size = New-Object System.Drawing.Size($BUTTON_WIDTH, $CONTROL_HEIGHT)
$button3.Tag = 3
$button3.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom
$form.Controls.Add($button3)

$button4 = New-Object System.Windows.Forms.Button
$button4.Text = "4: Category 4"
$button4.Size = New-Object System.Drawing.Size($BUTTON_WIDTH, $CONTROL_HEIGHT)
$button4.Tag = 4
$button4.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom
$form.Controls.Add($button4)

# Open folder button
$openButton = New-Object System.Windows.Forms.Button
$openButton.Text = "Open Folder"
$openButton.Size = New-Object System.Drawing.Size(150, $CONTROL_HEIGHT)
$openButton.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom
$form.Controls.Add($openButton)

# Help text
$helpLabel = New-Object System.Windows.Forms.Label
$helpLabel.Height = $CONTROL_HEIGHT - 10
$helpLabel.Text = "Use left/right arrow keys to navigate, press 1-4 to sort images"
$helpLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$helpLabel.Anchor = [System.Windows.Forms.AnchorStyles]::Left -bor 
                    [System.Windows.Forms.AnchorStyles]::Right -bor
                    [System.Windows.Forms.AnchorStyles]::Bottom
$form.Controls.Add($helpLabel)

# Create a dictionary to easily reference the buttons
$folderButtons = @{
    1 = $button1
    2 = $button2
    3 = $button3
    4 = $button4
}

# Variables to track current state
$script:currentIndex = 0
$script:imageFiles = @()
$script:currentDirectory = ""
$script:categoryFolders = @{
    1 = "1-Category1"
    2 = "2-Category2"
    3 = "3-Category3"
    4 = "4-Category4"
}

# Function to load images from a directory
function Load-Images {
    $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
    $folderBrowser.Description = "Select folder containing images"
    
    if ($folderBrowser.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $script:currentDirectory = $folderBrowser.SelectedPath
        
        # Search for images
        $script:imageFiles = Get-ChildItem -Path $script:currentDirectory -File | 
            Where-Object { $_.Extension -match '\.(jpg|jpeg|png|gif|bmp)$' -or 
                          $_.Extension -match '\.(JPG|JPEG|PNG|GIF|BMP)$' } |
            Sort-Object Name |
            Select-Object -ExpandProperty FullName
        
        if ($script:imageFiles.Count -eq 0) {
            [System.Windows.Forms.MessageBox]::Show("No image files found in selected directory.", "No Images", 
                [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
            return
        }
        
        # Create category subfolders if they don't exist
        foreach ($category in $script:categoryFolders.Keys) {
            $categoryPath = Join-Path -Path $script:currentDirectory -ChildPath $script:categoryFolders[$category]
            if (-not (Test-Path -Path $categoryPath)) {
                New-Item -Path $categoryPath -ItemType Directory | Out-Null
            }
        }
        
        $script:currentIndex = 0
        Show-CurrentImage
    }
}

# Function to display the current image
function Show-CurrentImage {
    if ($script:imageFiles.Count -eq 0) {
        $pictureBox.Image = $null
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
    }
    catch {
        $pictureBox.Image = $null
        $statusLabel.Text = "Error loading image"
        [System.Windows.Forms.MessageBox]::Show("Error displaying image: $_", "Error", 
            [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
}

# Function to navigate to the previous image
function Show-PreviousImage {
    if ($script:imageFiles.Count -eq 0) {
        return
    }
    
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
    
    $script:currentIndex++
    if ($script:currentIndex -ge $script:imageFiles.Count) {
        $script:currentIndex = 0
    }
    
    Show-CurrentImage
}

# Function to move current image to a category folder
function Move-ImageToCategory {
    param (
        [int]$category
    )
    
    if ($script:imageFiles.Count -eq 0) {
        return
    }
    
    if (-not $script:categoryFolders.ContainsKey($category)) {
        return
    }
    
    $currentImagePath = $script:imageFiles[$script:currentIndex]
    $fileName = Split-Path -Path $currentImagePath -Leaf
    $destinationFolder = Join-Path -Path $script:currentDirectory -ChildPath $script:categoryFolders[$category]
    $destinationPath = Join-Path -Path $destinationFolder -ChildPath $fileName
    
    try {
        # Clean up current image before moving
        if ($pictureBox.Image -ne $null) {
            $oldImage = $pictureBox.Image
            $pictureBox.Image = $null
            $oldImage.Dispose()
        }
        
        # Move the file
        Move-Item -Path $currentImagePath -Destination $destinationPath -Force
        
        # Flash button for feedback
        $originalColor = $folderButtons[$category].BackColor
        $folderButtons[$category].BackColor = [System.Drawing.Color]::LightGreen
        $form.Refresh()
        Start-Sleep -Milliseconds 200
        $folderButtons[$category].BackColor = $originalColor
        
        # Remove the moved file from the array
        $script:imageFiles = $script:imageFiles | Where-Object { $_ -ne $currentImagePath }
        
        if ($script:imageFiles.Count -eq 0) {
            $pictureBox.Image = $null
            $statusLabel.Text = "All images sorted!"
            return
        }
        
        # Adjust current index if needed
        if ($script:currentIndex -ge $script:imageFiles.Count) {
            $script:currentIndex = 0
        }
        
        Show-CurrentImage
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show("Error moving image: $_", "Error", 
            [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
}

# Function to update control positions when the form is resized
function Update-ControlPositions {
    # Positioning for control rows from bottom
    $bottomMargin = $PADDING

    # Position help label at the bottom
    $helpLabel.Width = $form.ClientSize.Width - ($PADDING * 2)
    $helpLabel.Left = $PADDING
    $helpLabel.Top = $form.ClientSize.Height - $helpLabel.Height - $bottomMargin

    # Position open button row above help label
    $openButton.Left = ($form.ClientSize.Width - $openButton.Width) / 2
    $openButton.Top = $helpLabel.Top - $openButton.Height - $BUTTONS_ROW_SPACING

    # Position category buttons row above open button
    $categoryRowY = $openButton.Top - $CONTROL_HEIGHT - $BUTTONS_ROW_SPACING

    # Calculate spacing between buttons
    $availableWidth = $form.ClientSize.Width - (2 * $PADDING) - ($BUTTON_WIDTH * 6)
    $buttonSpacing = [Math]::Max(10, $availableWidth / 5)

    # Position category buttons
    $button1.Left = $PADDING
    $button1.Top = $categoryRowY

    $button2.Left = $button1.Right + $buttonSpacing
    $button2.Top = $categoryRowY

    $button3.Left = $button2.Right + $buttonSpacing
    $button3.Top = $categoryRowY

    $button4.Left = $button3.Right + $buttonSpacing
    $button4.Top = $categoryRowY

    # Navigation buttons row below category row
    $navRowY = $categoryRowY + $CONTROL_HEIGHT + $BUTTONS_ROW_SPACING

    $prevButton.Left = $PADDING
    $prevButton.Top = $navRowY

    $nextButton.Left = $form.ClientSize.Width - $PADDING - $nextButton.Width
    $nextButton.Top = $navRowY

    # Position status label above buttons
    $statusLabel.Width = $form.ClientSize.Width - ($PADDING * 2)
    $statusLabel.Left = $PADDING
    $statusLabel.Top = $categoryRowY - $statusLabel.Height - $BUTTONS_ROW_SPACING

    # Size picture box to fill the remaining space
    $pictureBox.Left = $PADDING
    $pictureBox.Top = $PADDING
    $pictureBox.Width = $form.ClientSize.Width - ($PADDING * 2)
    $pictureBox.Height = $statusLabel.Top - $PADDING - $BUTTONS_ROW_SPACING
}

# Event for resize operations
$form.Add_Resize({
    Update-ControlPositions
})

# Add event handlers for buttons
$openButton.Add_Click({ Load-Images })
$prevButton.Add_Click({ Show-PreviousImage })
$nextButton.Add_Click({ Show-NextImage })

# Add handlers for category buttons
$button1.Add_Click({ Move-ImageToCategory -category 1 })
$button2.Add_Click({ Move-ImageToCategory -category 2 })
$button3.Add_Click({ Move-ImageToCategory -category 3 })
$button4.Add_Click({ Move-ImageToCategory -category 4 })

# Add keyboard shortcuts
$form.Add_KeyDown({
    param($sender, $e)
    
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
        
        # Category selection with number keys
        "D1" { 
            Move-ImageToCategory 1
            $e.Handled = $true
        }
        "D2" { 
            Move-ImageToCategory 2
            $e.Handled = $true
        }
        "D3" { 
            Move-ImageToCategory 3
            $e.Handled = $true
        }
        "D4" { 
            Move-ImageToCategory 4
            $e.Handled = $true
        }
        
        # Also allow numpad keys
        "NumPad1" { 
            Move-ImageToCategory 1
            $e.Handled = $true
        }
        "NumPad2" { 
            Move-ImageToCategory 2
            $e.Handled = $true
        }
        "NumPad3" { 
            Move-ImageToCategory 3
            $e.Handled = $true
        }
        "NumPad4" { 
            Move-ImageToCategory 4
            $e.Handled = $true
        }
        
        # Exit with Escape
        "Escape" {
            $form.Close()
        }
    }
})

# Handle form closing
$form.Add_FormClosing({
    param($sender, $e)
    if ($pictureBox.Image -ne $null) {
        $pictureBox.Image.Dispose()
    }
})

# Set initial positions
Update-ControlPositions

# Show the form
[void] $form.ShowDialog()