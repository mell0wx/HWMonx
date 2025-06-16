Add-Type -AssemblyName PresentationFramework

# Global Dark Mode Flag
$global:darkMode = $true

function Get-SystemInfo {
    return @{
        CPU        = Get-CimInstance Win32_Processor | Select-Object Name, NumberOfCores, NumberOfLogicalProcessors, MaxClockSpeed
        Memory     = Get-CimInstance Win32_PhysicalMemory | Select-Object Manufacturer, PartNumber, Capacity, Speed, BankLabel
        Motherboard= Get-CimInstance Win32_BaseBoard | Select-Object Manufacturer, Product, SerialNumber
        GPU        = Get-CimInstance Win32_VideoController | Select-Object Name, AdapterRAM, DriverVersion, VideoProcessor
        Storage    = Get-CimInstance Win32_DiskDrive | Select-Object Model, InterfaceType, Size, MediaType
        PCIe       = Get-PnpDevice -Class "PCI" | Where-Object { $_.Status -eq "OK" } | Select-Object Class, FriendlyName, Manufacturer
    }
}

# Formats the provided data object into a trimmed string for display in the UI.
function Format-InfoBlock ($data) {
    if ($data -is [System.Collections.IEnumerable] -and -not ($data -is [string])) {
        return ($data | Format-Table | Out-String).Trim()
    } else {
        return ($data | Out-String).Trim()
    }
}

function New-Tab($header, $text) {
    $tab = New-Object System.Windows.Controls.TabItem
    $tab.Header = $header

    $scrollViewer = New-Object System.Windows.Controls.ScrollViewer
    $scrollViewer.VerticalScrollBarVisibility = 'Auto'

    $textBlock = New-Object System.Windows.Controls.TextBlock
    $textBlock.Text = $text
    $textBlock.Margin = '10'
    $textBlock.FontFamily = 'Consolas'
    $textBlock.FontSize = 13
    $textBlock.TextWrapping = 'Wrap'

    $scrollViewer.Content = $textBlock
    $tab.Content = $scrollViewer
    return $tab
}

function New-Window {
    $window = New-Object System.Windows.Window
    $window.Title = "Hardware Info Viewer"
    $window.Width = 800
    $window.Height = 600
    $window.WindowStartupLocation = 'CenterScreen'

    $dockPanel = New-Object System.Windows.Controls.DockPanel
    $tabControl = New-Object System.Windows.Controls.TabControl

    $info = Get-SystemInfo
    foreach ($key in $info.Keys) {
        $formatted = Format-InfoBlock $info[$key]
        $tab = New-Tab $key $formatted
        $tabControl.Items.Add($tab) | Out-Null
    }

    $themeToggle = New-Object System.Windows.Controls.Button
    $themeToggle.Content = "Toggle Dark Mode"
    $themeToggle.Margin = '5'
    $themeToggle.HorizontalAlignment = 'Right'
    $themeToggle.Padding = '5,2'

    $themeToggle.Add_Click({
        $global:darkMode = -not $global:darkMode
        Set-Theme $window $darkMode
    })

    $topPanel = New-Object System.Windows.Controls.StackPanel
    $topPanel.Orientation = 'Horizontal'
    $topPanel.Children.Add($themeToggle) | Out-Null

    $dockPanel.Children.Add($topPanel) | Out-Null
    [System.Windows.Controls.DockPanel]::SetDock($topPanel, 'Top')

    $dockPanel.Children.Add($tabControl) | Out-Null
    $window.Content = $dockPanel

    Set-Theme $window $global:darkMode

    $window.ShowDialog()
}

function Set-Theme ($window, $dark) {
    Add-Type -AssemblyName PresentationCore
    if ($dark) {
        $bgColor = "#1e1e1e"
        $fgColor = "White"
    } else {
        $bgColor = "White"
        $fgColor = "Black"
    }

    $bgBrush = [System.Windows.Media.Brushes]::White
    $fgBrush = [System.Windows.Media.Brushes]::Black

    try {
        $bgBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString($bgColor)
        $fgBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString($fgColor)
    } catch {}

    function Set-ChildTheme($control) {
        if ($control -is [System.Windows.Controls.Panel]) {
            $control.Background = $bgBrush
            foreach ($child in $control.Children) {
                Set-ChildTheme $child
            }
        } elseif ($control -is [System.Windows.Controls.TabControl]) {
            $control.Background = $bgBrush
            $control.Foreground = $fgBrush
            foreach ($tab in $control.Items) {
                Set-ChildTheme $tab
            }
        } elseif ($control -is [System.Windows.Controls.TabItem]) {
            $control.Background = $bgBrush
            $control.Foreground = $fgBrush
            if ($control.Content) { Set-ChildTheme $control.Content }
        } elseif ($control -is [System.Windows.Controls.ContentControl]) {
            $control.Background = $bgBrush
            $control.Foreground = $fgBrush
            if ($control.Content) { Set-ChildTheme $control.Content }
        } elseif ($control -is [System.Windows.Controls.TextBlock]) {
            $control.Background = $bgBrush
            $control.Foreground = $fgBrush
        } elseif ($control -is [System.Windows.Controls.Button]) {
            $control.Background = $bgBrush
            $control.Foreground = $fgBrush
        }
    }

    $window.Background = $bgBrush
    $window.Foreground = $fgBrush
    Set-ChildTheme $window.Content
}

New-Window
