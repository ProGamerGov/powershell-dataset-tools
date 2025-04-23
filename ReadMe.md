# 🧰 PowerShell Dataset Tools

A collection of PowerShell GUI scripts for manually working with datasets, including tools for sorting and captioning image files. Built to support efficient manual workflows in dataset curation and research contexts.


## 🖼️ PowerShell Image Sorting Tool

![UI Screenshot](examples/example_image_sorting_tool.jpg)

A fast and intuitive PowerShell-based image sorting tool for quickly organizing photos into predefined categories using your keyboard. Meant for manual sorting tasks where automation isn’t feasible — just press 1–4 to send an image to its corresponding folder, or skip it to leave it in place.

---

### ✨ Features

- 📂 Quickly sort images into 4 custom category folders
- ⌨️ Keyboard shortcuts: `←` / `→` to navigate the UI, `1–4` to sort  
   - `Enter` activates the currently focused button (e.g., Previous/Next) for faster keyboard navigation
- 🖱️ Click-based UI with resizable controls
- 🖼️ Full image preview with zoom-to-fit
- 📁 Auto-creates category subfolders inside the selected folder

---

### 🚀 Getting Started

#### 🧾 Requirements

- Windows with PowerShell (tested on PowerShell 5.1)
- .NET Framework (for `System.Windows.Forms` and `System.Drawing`)

---

#### 🛠️ Usage

1. Clone this repo or download the `.ps1` script.

2. Run the script in PowerShell by right clicking on it and selecting 'Run with PowerShell' or by entering the following command like this:
   ```powershell
   .\ImageSortingTool.ps1
   ```

3. Select a folder with images that have a .jpg, .jpeg, .png, .gif, or .bmp extension.

4. Start sorting images
