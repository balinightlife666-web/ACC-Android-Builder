using Microsoft.Win32;
using System.Diagnostics;
using System.Drawing.Drawing2D;
using System.Net.NetworkInformation;
using System.Runtime.InteropServices;

namespace ArdaOS.Desktop;

public sealed class MainForm : Form
{
    private static readonly Color Bg = Color.FromArgb(3, 7, 11);
    private static readonly Color Panel = Color.FromArgb(10, 19, 27);
    private static readonly Color Panel2 = Color.FromArgb(13, 28, 38);
    private static readonly Color Cyan = Color.FromArgb(42, 238, 255);
    private static readonly Color Magenta = Color.FromArgb(255, 49, 153);
    private static readonly Color Text = Color.FromArgb(235, 247, 250);
    private static readonly Color Muted = Color.FromArgb(111, 148, 160);
    private static readonly Color Dim = Color.FromArgb(28, 69, 81);

    private readonly CodeStreamControl codeStream = new();
    private readonly Panel header = new();
    private readonly Label title = new();
    private readonly Label subtitle = new();
    private readonly Label clock = new();
    private readonly Label date = new();
    private readonly Label core = new();
    private readonly Label nodeCount = new();
    private readonly Panel telemetry = new();
    private readonly Label cpuValue = new();
    private readonly Label ramValue = new();
    private readonly Label storageValue = new();
    private readonly Label netValue = new();
    private readonly Panel nodeStack = new();
    private readonly Button accButton = new();
    private readonly Button waButton = new();
    private readonly Button noteButton = new();
    private readonly Button fbButton = new();
    private readonly Button igButton = new();
    private readonly Button appsButton = new();
    private readonly Button minimizeButton = new();
    private readonly Button settingsButton = new();
    private readonly Button exitButton = new();
    private readonly Button startupButton = new();
    private readonly Label leftRail = new();
    private readonly Label commandText = new();
    private readonly System.Windows.Forms.Timer telemetryTimer = new() { Interval = 1000 };

    private Panel? drawer;
    private TextBox? appSearch;
    private FlowLayoutPanel? appFlow;
    private List<AppShortcut> shortcuts = new();

    private long lastIdle;
    private long lastKernel;
    private long lastUser;
    private bool cpuReady;

    public MainForm()
    {
        Text = "ARDA OS Desktop";
        FormBorderStyle = FormBorderStyle.None;
        WindowState = FormWindowState.Maximized;
        StartPosition = FormStartPosition.CenterScreen;
        BackColor = Bg;
        ForeColor = Text;
        KeyPreview = true;
        DoubleBuffered = true;
        MinimumSize = new Size(900, 600);

        BuildUi();
        LoadShortcuts();
        UpdateTelemetry();

        telemetryTimer.Tick += (_, _) => UpdateTelemetry();
        telemetryTimer.Start();

        Resize += (_, _) => LayoutUi();
        Shown += (_, _) =>
        {
            LayoutUi();
            codeStream.SendToBack();
        };

        KeyDown += (_, e) =>
        {
            if (e.KeyCode is Keys.Escape or Keys.F12)
            {
                Close();
            }
            else if (e.Control && e.KeyCode == Keys.Space)
            {
                ToggleDrawer();
            }
        };
    }

    private Font Mono(float size, FontStyle style = FontStyle.Regular)
        => new("Consolas", size, style, GraphicsUnit.Point);

    private void BuildUi()
    {
        codeStream.Dock = DockStyle.Fill;
        Controls.Add(codeStream);

        header.BackColor = Color.FromArgb(228, Panel);
        header.Paint += (_, e) => DrawHudBorder(e.Graphics, header.ClientRectangle, Cyan, dashed: true);
        Controls.Add(header);

        title.Text = "ARDA OS // NADMO CYBERDECK";
        title.ForeColor = Cyan;
        title.Font = Mono(16, FontStyle.Bold);
        title.AutoSize = true;
        header.Controls.Add(title);

        subtitle.Text = "DESKTOP NODE  //  SAFE SHELL  //  CODESTREAM ACTIVE";
        subtitle.ForeColor = Muted;
        subtitle.Font = Mono(9);
        subtitle.AutoSize = true;
        header.Controls.Add(subtitle);

        minimizeButton.Text = "—";
        ConfigureTinyButton(minimizeButton, Cyan);
        minimizeButton.Click += (_, _) => WindowState = FormWindowState.Minimized;
        header.Controls.Add(minimizeButton);

        settingsButton.Text = "⚙";
        ConfigureTinyButton(settingsButton, Cyan);
        settingsButton.Click += (_, _) => OpenTarget("ms-settings:");
        header.Controls.Add(settingsButton);

        exitButton.Text = "×";
        ConfigureTinyButton(exitButton, Magenta);
        exitButton.Click += (_, _) => Close();
        header.Controls.Add(exitButton);

        clock.ForeColor = Text;
        clock.Font = Mono(42, FontStyle.Bold);
        clock.AutoSize = true;
        Controls.Add(clock);

        core.Text = "CORE // ONLINE";
        core.ForeColor = Cyan;
        core.Font = Mono(11, FontStyle.Bold);
        core.AutoSize = true;
        Controls.Add(core);

        date.ForeColor = Text;
        date.Font = Mono(10);
        date.AutoSize = true;
        Controls.Add(date);

        nodeCount.ForeColor = Magenta;
        nodeCount.Font = Mono(9, FontStyle.Bold);
        nodeCount.AutoSize = true;
        Controls.Add(nodeCount);

        telemetry.BackColor = Color.Transparent;
        Controls.Add(telemetry);
        AddTelemetryTile("CPU //", cpuValue, 0);
        AddTelemetryTile("RAM //", ramValue, 1);
        AddTelemetryTile("STO //", storageValue, 2);
        AddTelemetryTile("NET //", netValue, 3);

        leftRail.Text = "│\n│\n◆\n│\n│\n│\n└─";
        leftRail.ForeColor = Cyan;
        leftRail.Font = Mono(17);
        leftRail.AutoSize = true;
        Controls.Add(leftRail);

        commandText.Text = "ROOT@ARDA\r\nFASTLINK READY\r\nWINDOWS SHELL INTACT\r\nALT+TAB ENABLED";
        commandText.ForeColor = Muted;
        commandText.Font = Mono(9);
        commandText.AutoSize = true;
        Controls.Add(commandText);

        nodeStack.BackColor = Color.Transparent;
        Controls.Add(nodeStack);

        ConfigureNodeButton(accButton, "ACC OS X        >", Cyan, primary: true);
        ConfigureNodeButton(waButton, "WHATSAPP        >", Magenta);
        ConfigureNodeButton(noteButton, "NOTE            >", Cyan);
        ConfigureNodeButton(fbButton, "FACEBOOK        >", Cyan);
        ConfigureNodeButton(igButton, "INSTAGRAM       >", Magenta);

        accButton.Click += (_, _) => LaunchAccOs();
        waButton.Click += (_, _) => LaunchWhatsApp();
        noteButton.Click += (_, _) => OpenTarget("notepad.exe");
        fbButton.Click += (_, _) => OpenTarget("https://www.facebook.com/");
        igButton.Click += (_, _) => OpenTarget("https://www.instagram.com/");

        nodeStack.Controls.AddRange([accButton, waButton, noteButton, fbButton, igButton]);

        appsButton.Text = "APPS  >";
        ConfigureNodeButton(appsButton, appsButton.Text, Cyan);
        appsButton.TextAlign = ContentAlignment.MiddleCenter;
        appsButton.Click += (_, _) => ToggleDrawer();
        Controls.Add(appsButton);

        startupButton.FlatStyle = FlatStyle.Flat;
        startupButton.Font = Mono(8, FontStyle.Bold);
        startupButton.ForeColor = Muted;
        startupButton.BackColor = Color.FromArgb(190, Panel);
        startupButton.FlatAppearance.BorderColor = Dim;
        startupButton.FlatAppearance.BorderSize = 1;
        startupButton.Cursor = Cursors.Hand;
        startupButton.Click += (_, _) => ToggleStartup();
        Controls.Add(startupButton);
        UpdateStartupText();

        BringMainUiToFront();
    }

    private void BringMainUiToFront()
    {
        foreach (Control c in new Control[]
        {
            header, clock, core, date, nodeCount, telemetry, leftRail,
            commandText, nodeStack, appsButton, startupButton
        })
        {
            c.BringToFront();
        }
    }

    private void ConfigureTinyButton(Button b, Color accent)
    {
        b.FlatStyle = FlatStyle.Flat;
        b.FlatAppearance.BorderColor = accent;
        b.FlatAppearance.BorderSize = 1;
        b.FlatAppearance.MouseDownBackColor = Color.FromArgb(80, accent);
        b.FlatAppearance.MouseOverBackColor = Color.FromArgb(35, accent);
        b.BackColor = Color.FromArgb(190, Panel2);
        b.ForeColor = accent;
        b.Font = Mono(12, FontStyle.Bold);
        b.Cursor = Cursors.Hand;
        b.TabStop = false;
    }

    private void ConfigureNodeButton(Button b, string text, Color accent, bool primary = false)
    {
        b.Text = text;
        b.FlatStyle = FlatStyle.Flat;
        b.FlatAppearance.BorderColor = accent;
        b.FlatAppearance.BorderSize = 1;
        b.FlatAppearance.MouseDownBackColor = Color.FromArgb(95, accent);
        b.FlatAppearance.MouseOverBackColor = Color.FromArgb(42, accent);
        b.BackColor = Color.FromArgb(primary ? 225 : 205, primary ? Panel2 : Panel);
        b.ForeColor = primary ? Cyan : Text;
        b.Font = Mono(primary ? 12 : 10, FontStyle.Bold);
        b.TextAlign = ContentAlignment.MiddleLeft;
        b.Padding = new Padding(12, 0, 10, 0);
        b.Cursor = Cursors.Hand;
        b.TabStop = false;
    }

    private void AddTelemetryTile(string caption, Label value, int index)
    {
        var tile = new Panel
        {
            BackColor = Color.FromArgb(188, Panel),
            Tag = index
        };
        tile.Paint += (_, e) => DrawHudBorder(e.Graphics, tile.ClientRectangle, Dim, dashed: false);

        var key = new Label
        {
            Text = caption,
            ForeColor = Muted,
            Font = Mono(8, FontStyle.Bold),
            AutoSize = true,
            Location = new Point(8, 6)
        };
        tile.Controls.Add(key);

        value.ForeColor = Cyan;
        value.Font = Mono(13, FontStyle.Bold);
        value.AutoSize = true;
        value.Location = new Point(8, 22);
        tile.Controls.Add(value);

        telemetry.Controls.Add(tile);
    }

    private void LayoutUi()
    {
        int w = ClientSize.Width;
        int h = ClientSize.Height;
        if (w <= 0 || h <= 0) return;

        int margin = Math.Max(24, w / 55);
        int headerW = Math.Min(820, w - margin * 2);
        header.SetBounds(margin, 22, headerW, 72);

        title.Location = new Point(28, 14);
        subtitle.Location = new Point(30, 42);

        exitButton.SetBounds(header.Width - 48, 14, 34, 40);
        settingsButton.SetBounds(header.Width - 90, 14, 34, 40);
        minimizeButton.SetBounds(header.Width - 132, 14, 34, 40);

        clock.Location = new Point(margin + 6, header.Bottom + 34);
        core.Location = new Point(margin + 320, header.Bottom + 50);
        date.Location = new Point(margin + 320, header.Bottom + 74);
        nodeCount.Location = new Point(margin + 6, header.Bottom + 105);

        telemetry.SetBounds(margin, header.Bottom + 132, Math.Min(520, w / 2), 62);
        int tileGap = 6;
        int tileW = (telemetry.Width - tileGap * 3) / 4;
        int i = 0;
        foreach (Control tile in telemetry.Controls)
        {
            tile.SetBounds(i * (tileW + tileGap), 0, tileW, 58);
            i++;
        }

        int stackW = Math.Clamp(w / 4, 250, 340);
        int stackX = w - stackW - margin;
        int stackY = Math.Max(header.Bottom + 150, h / 3);
        nodeStack.SetBounds(stackX, stackY, stackW, 270);

        int buttonH = 42;
        int gap = 8;
        accButton.SetBounds(0, 0, stackW, 50);
        waButton.SetBounds(0, 50 + gap, stackW, buttonH);
        noteButton.SetBounds(0, 50 + gap + (buttonH + gap), stackW, buttonH);
        fbButton.SetBounds(0, 50 + gap + (buttonH + gap) * 2, stackW, buttonH);
        igButton.SetBounds(0, 50 + gap + (buttonH + gap) * 3, stackW, buttonH);

        leftRail.Location = new Point(margin + 8, stackY + 12);
        commandText.Location = new Point(margin + 62, stackY + 34);

        appsButton.SetBounds(w - margin - 150, h - 76, 150, 40);
        startupButton.SetBounds(margin, h - 64, 150, 30);

        if (drawer != null && drawer.Visible)
            LayoutDrawer();
    }

    private void DrawHudBorder(Graphics g, Rectangle rect, Color color, bool dashed)
    {
        g.SmoothingMode = SmoothingMode.AntiAlias;
        using var pen = new Pen(color, 1.2f);
        if (dashed) pen.DashPattern = [7f, 5f];
        rect.Width -= 1;
        rect.Height -= 1;
        g.DrawRectangle(pen, rect);
    }

    private void UpdateTelemetry()
    {
        clock.Text = DateTime.Now.ToString("HH:mm:ss");
        date.Text = DateTime.Now.ToString("ddd • dd MMM yyyy");
        nodeCount.Text = $"{shortcuts.Count} START NODES  //  ONLINE";

        cpuValue.Text = $"{GetCpuUsage():0}%";

        var mem = GetMemory();
        ramValue.Text = mem.total == 0
            ? "--"
            : $"{(mem.total - mem.available) / 1024d / 1024d / 1024d:0.0}G";

        try
        {
            string root = Path.GetPathRoot(Environment.SystemDirectory) ?? "C:\\";
            var drive = new DriveInfo(root);
            storageValue.Text = $"{drive.AvailableFreeSpace / 1024d / 1024d / 1024d:0}G";
        }
        catch
        {
            storageValue.Text = "--";
        }

        netValue.Text = NetworkInterface.GetIsNetworkAvailable() ? "ON" : "OFF";
    }

    private void LaunchAccOs()
    {
        var hit = shortcuts.FirstOrDefault(s =>
            s.Name.Contains("ACC OS X", StringComparison.OrdinalIgnoreCase) ||
            s.Name.Equals("ACC OS", StringComparison.OrdinalIgnoreCase));

        if (hit != null)
        {
            LaunchShortcut(hit);
            return;
        }

        ShowDrawer("ACC");
    }

    private void LaunchWhatsApp()
    {
        try
        {
            Process.Start(new ProcessStartInfo("whatsapp:") { UseShellExecute = true });
        }
        catch
        {
            OpenTarget("https://web.whatsapp.com/");
        }
    }

    private void OpenTarget(string target)
    {
        try
        {
            Process.Start(new ProcessStartInfo(target) { UseShellExecute = true });
        }
        catch (Exception ex)
        {
            MessageBox.Show($"Tidak bisa membuka target.\n\n{ex.Message}", "ARDA OS", MessageBoxButtons.OK, MessageBoxIcon.Warning);
        }
    }

    private void LoadShortcuts()
    {
        var found = new List<AppShortcut>();
        var roots = new[]
        {
            Environment.GetFolderPath(Environment.SpecialFolder.StartMenu),
            Environment.GetFolderPath(Environment.SpecialFolder.CommonStartMenu)
        };

        foreach (var root in roots.Where(Directory.Exists))
        {
            try
            {
                foreach (var file in Directory.EnumerateFiles(root, "*.*", SearchOption.AllDirectories)
                                             .Where(f => f.EndsWith(".lnk", StringComparison.OrdinalIgnoreCase)
                                                      || f.EndsWith(".url", StringComparison.OrdinalIgnoreCase)))
                {
                    string name = Path.GetFileNameWithoutExtension(file);
                    if (string.IsNullOrWhiteSpace(name)) continue;
                    found.Add(new AppShortcut(name, file));
                }
            }
            catch { }
        }

        shortcuts = found
            .GroupBy(s => s.Name, StringComparer.OrdinalIgnoreCase)
            .Select(g => g.First())
            .OrderBy(s => s.Name, StringComparer.OrdinalIgnoreCase)
            .ToList();
    }

    private void ToggleDrawer()
    {
        if (drawer is { Visible: true })
        {
            drawer.Visible = false;
            BringMainUiToFront();
        }
        else
        {
            ShowDrawer("");
        }
    }

    private void ShowDrawer(string query)
    {
        if (drawer == null)
            BuildDrawer();

        drawer!.Visible = true;
        drawer.BringToFront();
        LayoutDrawer();

        if (appSearch != null)
        {
            appSearch.Text = query;
            appSearch.SelectionStart = appSearch.TextLength;
            appSearch.Focus();
        }
        RenderAppDrawer();
    }

    private void BuildDrawer()
    {
        drawer = new Panel
        {
            BackColor = Color.FromArgb(248, 5, 11, 16),
            Visible = false
        };
        drawer.Paint += (_, e) => DrawHudBorder(e.Graphics, drawer.ClientRectangle, Cyan, dashed: true);
        Controls.Add(drawer);

        var drawerTitle = new Label
        {
            Text = "APP DRAWER // WINDOWS START NODES",
            ForeColor = Cyan,
            Font = Mono(12, FontStyle.Bold),
            AutoSize = true,
            Location = new Point(22, 18)
        };
        drawer.Controls.Add(drawerTitle);

        var close = new Button { Text = "×" };
        ConfigureTinyButton(close, Magenta);
        close.Click += (_, _) => drawer.Visible = false;
        drawer.Controls.Add(close);
        close.Name = "DrawerClose";

        appSearch = new TextBox
        {
            BorderStyle = BorderStyle.FixedSingle,
            BackColor = Panel2,
            ForeColor = Text,
            Font = Mono(11),
            PlaceholderText = "SEARCH APPS...",
            Location = new Point(22, 58)
        };
        appSearch.TextChanged += (_, _) => RenderAppDrawer();
        drawer.Controls.Add(appSearch);

        appFlow = new FlowLayoutPanel
        {
            AutoScroll = true,
            WrapContents = true,
            FlowDirection = FlowDirection.LeftToRight,
            BackColor = Color.Transparent,
            Location = new Point(22, 112)
        };
        drawer.Controls.Add(appFlow);
    }

    private void LayoutDrawer()
    {
        if (drawer == null) return;
        int dw = Math.Clamp((int)(ClientSize.Width * 0.72), 720, 1040);
        int dh = Math.Clamp((int)(ClientSize.Height * 0.76), 500, 760);
        drawer.SetBounds((ClientSize.Width - dw) / 2, (ClientSize.Height - dh) / 2, dw, dh);

        var close = drawer.Controls.Find("DrawerClose", true).FirstOrDefault();
        close?.SetBounds(dw - 58, 14, 36, 36);

        appSearch?.SetBounds(22, 58, dw - 44, 36);
        appFlow?.SetBounds(22, 108, dw - 44, dh - 130);
    }

    private void RenderAppDrawer()
    {
        if (appFlow == null) return;

        string q = appSearch?.Text.Trim() ?? "";
        appFlow.SuspendLayout();
        appFlow.Controls.Clear();

        IEnumerable<AppShortcut> list = shortcuts;
        if (!string.IsNullOrEmpty(q))
            list = list.Where(s => s.Name.Contains(q, StringComparison.OrdinalIgnoreCase));

        foreach (var item in list.Take(250))
        {
            var b = new Button
            {
                Text = item.Name,
                Width = 190,
                Height = 46,
                Margin = new Padding(5),
                FlatStyle = FlatStyle.Flat,
                BackColor = Color.FromArgb(205, Panel),
                ForeColor = Text,
                Font = Mono(9, FontStyle.Bold),
                TextAlign = ContentAlignment.MiddleLeft,
                Padding = new Padding(10, 0, 6, 0),
                Cursor = Cursors.Hand,
                Tag = item
            };
            b.FlatAppearance.BorderColor = Dim;
            b.FlatAppearance.MouseOverBackColor = Color.FromArgb(42, Cyan);
            b.FlatAppearance.MouseDownBackColor = Color.FromArgb(90, Cyan);
            b.Click += (_, _) => LaunchShortcut(item);
            appFlow.Controls.Add(b);
        }

        appFlow.ResumeLayout();
    }

    private void LaunchShortcut(AppShortcut shortcut)
    {
        try
        {
            Process.Start(new ProcessStartInfo(shortcut.Path) { UseShellExecute = true });
        }
        catch (Exception ex)
        {
            MessageBox.Show($"Tidak bisa membuka {shortcut.Name}.\n\n{ex.Message}", "ARDA OS", MessageBoxButtons.OK, MessageBoxIcon.Warning);
        }
    }

    private void ToggleStartup()
    {
        const string keyPath = @"Software\Microsoft\Windows\CurrentVersion\Run";
        using var key = Registry.CurrentUser.OpenSubKey(keyPath, writable: true);
        if (key == null) return;

        if (IsStartupEnabled())
        {
            key.DeleteValue("ARDA OS Desktop", throwOnMissingValue: false);
        }
        else
        {
            string exe = Environment.ProcessPath ?? Application.ExecutablePath;
            key.SetValue("ARDA OS Desktop", $"\"{exe}\"");
        }

        UpdateStartupText();
    }

    private bool IsStartupEnabled()
    {
        const string keyPath = @"Software\Microsoft\Windows\CurrentVersion\Run";
        using var key = Registry.CurrentUser.OpenSubKey(keyPath);
        return key?.GetValue("ARDA OS Desktop") != null;
    }

    private void UpdateStartupText()
    {
        startupButton.Text = IsStartupEnabled() ? "AUTOSTART // ON" : "AUTOSTART // OFF";
        startupButton.ForeColor = IsStartupEnabled() ? Cyan : Muted;
    }

    private double GetCpuUsage()
    {
        if (!GetSystemTimes(out var idleFt, out var kernelFt, out var userFt))
            return 0;

        long idle = ToLong(idleFt);
        long kernel = ToLong(kernelFt);
        long user = ToLong(userFt);

        if (!cpuReady)
        {
            lastIdle = idle;
            lastKernel = kernel;
            lastUser = user;
            cpuReady = true;
            return 0;
        }

        long idleDelta = idle - lastIdle;
        long kernelDelta = kernel - lastKernel;
        long userDelta = user - lastUser;
        long total = kernelDelta + userDelta;

        lastIdle = idle;
        lastKernel = kernel;
        lastUser = user;

        if (total <= 0) return 0;
        double used = 100.0 - (idleDelta * 100.0 / total);
        return Math.Clamp(used, 0, 100);
    }

    private static long ToLong(FILETIME ft)
        => ((long)ft.dwHighDateTime << 32) | ft.dwLowDateTime;

    private static (ulong total, ulong available) GetMemory()
    {
        var s = new MEMORYSTATUSEX();
        s.dwLength = (uint)Marshal.SizeOf<MEMORYSTATUSEX>();
        if (!GlobalMemoryStatusEx(ref s)) return (0, 0);
        return (s.ullTotalPhys, s.ullAvailPhys);
    }

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern bool GetSystemTimes(out FILETIME idleTime, out FILETIME kernelTime, out FILETIME userTime);

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern bool GlobalMemoryStatusEx(ref MEMORYSTATUSEX lpBuffer);

    [StructLayout(LayoutKind.Sequential)]
    private struct FILETIME
    {
        public uint dwLowDateTime;
        public uint dwHighDateTime;
    }

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Auto)]
    private struct MEMORYSTATUSEX
    {
        public uint dwLength;
        public uint dwMemoryLoad;
        public ulong ullTotalPhys;
        public ulong ullAvailPhys;
        public ulong ullTotalPageFile;
        public ulong ullAvailPageFile;
        public ulong ullTotalVirtual;
        public ulong ullAvailVirtual;
        public ulong ullAvailExtendedVirtual;
    }

    private sealed record AppShortcut(string Name, string Path);
}

internal sealed class CodeStreamControl : Control
{
    private readonly System.Windows.Forms.Timer timer = new() { Interval = 60 };
    private readonly Font font = new("Consolas", 10f, FontStyle.Regular, GraphicsUnit.Point);
    private readonly string[] lines =
    [
        "ACC_OS_X::BOOT   NODE_SCAN   CACHE_WARM   DESKTOP_LINK_READY",
        "root@arda:~$ mount --cyberdeck /nadmo/desktop",
        "WINDOWS_SHELL::INTACT   SAFE_MODE::TRUE",
        "WA_CHANNEL_READY   IG_MEDIA_LINK::ONLINE   FB_SOCIAL::SYNC",
        "kernel.trace -> cpu ram storage network",
        "0xA9 NODE HANDSHAKE ACCEPTED   SESSION::LOCAL",
        "SYS_CLOCK SYNCHRONIZED   START_MENU_INDEX::READY",
        "NADMO://FASTLINK/ACC_OS_X/ROOT",
        "decrypt(session) -> access_granted",
        "launcher.apps --windows-start-nodes --search",
        "telemetry.stream cpu ram storage net",
        "ALT_TAB::ENABLED   EXPLORER::RUNNING",
        "comms.route -> whatsapp://desktop",
        "media.route -> instagram://browser",
        "social.route -> facebook://browser",
        "notes.mount -> notepad.exe",
        "SYSTEM CACHE WARM   TOUCH_FEEDBACK READY",
        "CYBERDECK HUD DESKTOP v0.1   CODESTREAM ACTIVE"
    ];

    private float offset;

    public CodeStreamControl()
    {
        SetStyle(ControlStyles.UserPaint |
                 ControlStyles.AllPaintingInWmPaint |
                 ControlStyles.OptimizedDoubleBuffer |
                 ControlStyles.ResizeRedraw, true);
        BackColor = Color.FromArgb(3, 7, 11);
        timer.Tick += (_, _) =>
        {
            offset -= 0.65f;
            if (offset < -24f) offset += 24f;
            Invalidate();
        };
        timer.Start();
    }

    protected override void Dispose(bool disposing)
    {
        if (disposing)
        {
            timer.Dispose();
            font.Dispose();
        }
        base.Dispose(disposing);
    }

    protected override void OnPaint(PaintEventArgs e)
    {
        e.Graphics.Clear(BackColor);
        e.Graphics.TextRenderingHint = System.Drawing.Text.TextRenderingHint.ClearTypeGridFit;

        using var cyan = new SolidBrush(Color.FromArgb(78, 42, 238, 255));
        using var magenta = new SolidBrush(Color.FromArgb(44, 255, 49, 153));
        using var scan = new Pen(Color.FromArgb(14, 100, 180, 190), 1f);

        float lineHeight = 26f;
        int count = (int)Math.Ceiling(Height / lineHeight) + 3;

        for (int i = 0; i < count; i++)
        {
            float y = offset + i * lineHeight;
            int idx = i % lines.Length;
            string prefix = $"{(i * 19 + 0x1A) & 0xFF:X2} ";
            e.Graphics.DrawString(prefix + lines[idx], font, cyan, 12f, y);

            if (i % 4 == 2)
            {
                e.Graphics.DrawString(":: " + lines[(idx + 7) % lines.Length], font, magenta, 160f, y + 10f);
            }
        }

        for (int y = 0; y < Height; y += 5)
            e.Graphics.DrawLine(scan, 0, y, Width, y);
    }
}
