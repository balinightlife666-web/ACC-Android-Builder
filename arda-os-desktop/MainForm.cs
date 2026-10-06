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
    private static readonly Color UiText = Color.FromArgb(235, 247, 250);
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

    private readonly Panel corePanel = new();
    private readonly Label corePanelTitle = new();
    private readonly Label corePanelInfo = new();
    private readonly Panel coreActivityRail = new();
    private readonly Panel coreActivityFill = new();

    private readonly Panel nodeStack = new();
    private readonly Button accButton = new();
    private readonly Button waButton = new();
    private readonly Button noteButton = new();
    private readonly Button fbButton = new();
    private readonly Button igButton = new();

    private readonly FlowLayoutPanel quickModules = new();
    private readonly Button filesButton = new();
    private readonly Button chromeButton = new();
    private readonly Button spotifyButton = new();
    private readonly Button discordButton = new();

    private readonly Button appsButton = new();
    private readonly Button minimizeButton = new();
    private readonly Button settingsButton = new();
    private readonly Button exitButton = new();
    private readonly Button startupButton = new();
    private readonly Button taskbarButton = new();

    private readonly Label leftRail = new();
    private readonly Label commandText = new();
    private readonly Label footer = new();

    private readonly System.Windows.Forms.Timer telemetryTimer = new() { Interval = 1000 };

    private Panel? drawer;
    private TextBox? appSearch;
    private FlowLayoutPanel? appFlow;
    private List<AppShortcut> shortcuts = new();

    private long lastIdle;
    private long lastKernel;
    private long lastUser;
    private bool cpuReady;
    private bool taskbarHidden;

    public MainForm()
    {
        base.Text = "ARDA OS Desktop";
        FormBorderStyle = FormBorderStyle.None;
        WindowState = FormWindowState.Maximized;
        StartPosition = FormStartPosition.CenterScreen;
        BackColor = Bg;
        ForeColor = UiText;
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

        FormClosing += (_, _) =>
        {
            if (taskbarHidden)
                SetTaskbarVisible(true);
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
            else if (e.Control && e.KeyCode == Keys.H)
            {
                ToggleTaskbar();
            }
        };
    }

    private Font Mono(float size, FontStyle style = FontStyle.Regular)
        => new("Consolas", size, style, GraphicsUnit.Point);

    private void BuildUi()
    {
        codeStream.Dock = DockStyle.Fill;
        Controls.Add(codeStream);

        header.BackColor = Color.FromArgb(220, Panel);
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

        clock.ForeColor = Color.White;
        clock.Font = Mono(54, FontStyle.Bold);
        clock.AutoSize = true;
        Controls.Add(clock);

        core.Text = "CORE // ONLINE";
        core.ForeColor = Cyan;
        core.Font = Mono(11, FontStyle.Bold);
        core.AutoSize = true;
        Controls.Add(core);

        date.ForeColor = UiText;
        date.Font = Mono(10);
        date.AutoSize = true;
        Controls.Add(date);

        nodeCount.ForeColor = Magenta;
        nodeCount.Font = Mono(9, FontStyle.Bold);
        nodeCount.AutoSize = true;
        Controls.Add(nodeCount);

        telemetry.BackColor = Color.Transparent;
        Controls.Add(telemetry);
        AddTelemetryTile("CPU //", cpuValue);
        AddTelemetryTile("RAM //", ramValue);
        AddTelemetryTile("STO //", storageValue);
        AddTelemetryTile("NET //", netValue);

        BuildCorePanel();

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

        ConfigureNodeButton(accButton, "ACC OS X       >", Cyan, primary: true);
        ConfigureNodeButton(waButton, "WHATSAPP       >", Magenta);
        ConfigureNodeButton(noteButton, "NOTE           >", Cyan);
        ConfigureNodeButton(fbButton, "FACEBOOK       >", Cyan);
        ConfigureNodeButton(igButton, "INSTAGRAM      >", Magenta);

        accButton.Click += (_, _) => LaunchAccOs();
        waButton.Click += (_, _) => LaunchWhatsApp();
        noteButton.Click += (_, _) => OpenTarget("notepad.exe");
        fbButton.Click += (_, _) => OpenTarget("https://www.facebook.com/");
        igButton.Click += (_, _) => OpenTarget("https://www.instagram.com/");

        nodeStack.Controls.AddRange([accButton, waButton, noteButton, fbButton, igButton]);

        BuildQuickModules();

        ConfigureNodeButton(appsButton, "APPS  >", Cyan);
        appsButton.TextAlign = ContentAlignment.MiddleCenter;
        appsButton.Click += (_, _) => ToggleDrawer();
        Controls.Add(appsButton);

        ConfigureUtilityButton(startupButton);
        startupButton.Click += (_, _) => ToggleStartup();
        Controls.Add(startupButton);
        UpdateStartupText();

        ConfigureUtilityButton(taskbarButton);
        taskbarButton.Click += (_, _) => ToggleTaskbar();
        Controls.Add(taskbarButton);
        UpdateTaskbarText();

        footer.Text = "v0.3  //  RIGHT STATUS LAYOUT  //  CTRL+SPACE APPS  //  CTRL+H TASKBAR  //  F12 EXIT";
        footer.ForeColor = Muted;
        footer.Font = Mono(8);
        footer.AutoSize = true;
        Controls.Add(footer);

        BringMainUiToFront();
    }

    private void BuildCorePanel()
    {
        corePanel.BackColor = Color.FromArgb(175, Panel);
        corePanel.Paint += (_, e) => DrawHudBorder(e.Graphics, corePanel.ClientRectangle, Dim, dashed: true);
        Controls.Add(corePanel);

        corePanelTitle.Text = "ACC CORE // SYSTEM STATUS";
        corePanelTitle.ForeColor = Cyan;
        corePanelTitle.Font = Mono(10, FontStyle.Bold);
        corePanelTitle.AutoSize = true;
        corePanel.Controls.Add(corePanelTitle);

        corePanelInfo.Text = "SESSION LOCAL\r\nSHELL SAFE\r\nFASTLINK READY";
        corePanelInfo.ForeColor = UiText;
        corePanelInfo.Font = Mono(9);
        corePanelInfo.AutoSize = true;
        corePanel.Controls.Add(corePanelInfo);

        coreActivityRail.BackColor = Color.FromArgb(80, 80, 100, 108);
        corePanel.Controls.Add(coreActivityRail);

        coreActivityFill.BackColor = Cyan;
        coreActivityRail.Controls.Add(coreActivityFill);
    }

    private void BuildQuickModules()
    {
        quickModules.BackColor = Color.Transparent;
        quickModules.FlowDirection = FlowDirection.LeftToRight;
        quickModules.WrapContents = false;
        quickModules.AutoSize = false;
        Controls.Add(quickModules);

        ConfigureQuickModule(filesButton, "FILES", Cyan);
        ConfigureQuickModule(chromeButton, "CHROME", Cyan);
        ConfigureQuickModule(spotifyButton, "SPOTIFY", Magenta);
        ConfigureQuickModule(discordButton, "DISCORD", Magenta);

        filesButton.Click += (_, _) => OpenTarget("explorer.exe");
        chromeButton.Click += (_, _) => LaunchChrome();
        spotifyButton.Click += (_, _) => LaunchSpotify();
        discordButton.Click += (_, _) => LaunchDiscord();

        quickModules.Controls.AddRange([filesButton, chromeButton, spotifyButton, discordButton]);
    }

    private void BringMainUiToFront()
    {
        foreach (Control c in new Control[]
        {
            header, clock, core, date, nodeCount, telemetry, corePanel,
            leftRail, commandText, nodeStack, quickModules, appsButton,
            startupButton, taskbarButton, footer
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
        b.BackColor = Color.FromArgb(primary ? 218 : 192, primary ? Panel2 : Panel);
        b.ForeColor = primary ? Cyan : UiText;
        b.Font = Mono(primary ? 11 : 9, FontStyle.Bold);
        b.TextAlign = ContentAlignment.MiddleLeft;
        b.Padding = new Padding(10, 0, 8, 0);
        b.Cursor = Cursors.Hand;
        b.TabStop = false;
    }

    private void ConfigureQuickModule(Button b, string label, Color accent)
    {
        b.Text = label;
        b.Width = 104;
        b.Height = 34;
        b.Margin = new Padding(0, 0, 7, 0);
        b.FlatStyle = FlatStyle.Flat;
        b.FlatAppearance.BorderColor = accent;
        b.FlatAppearance.BorderSize = 1;
        b.FlatAppearance.MouseDownBackColor = Color.FromArgb(90, accent);
        b.FlatAppearance.MouseOverBackColor = Color.FromArgb(38, accent);
        b.BackColor = Color.FromArgb(175, Panel);
        b.ForeColor = UiText;
        b.Font = Mono(8, FontStyle.Bold);
        b.Cursor = Cursors.Hand;
        b.TabStop = false;
    }

    private void ConfigureUtilityButton(Button b)
    {
        b.FlatStyle = FlatStyle.Flat;
        b.Font = Mono(8, FontStyle.Bold);
        b.ForeColor = Muted;
        b.BackColor = Color.FromArgb(175, Panel);
        b.FlatAppearance.BorderColor = Dim;
        b.FlatAppearance.BorderSize = 1;
        b.FlatAppearance.MouseOverBackColor = Color.FromArgb(30, Cyan);
        b.Cursor = Cursors.Hand;
        b.TabStop = false;
    }

    private void AddTelemetryTile(string caption, Label value)
    {
        var tile = new Panel
        {
            BackColor = Color.FromArgb(180, Panel)
        };
        tile.Paint += (_, e) => DrawHudBorder(e.Graphics, tile.ClientRectangle, Dim, dashed: false);

        var key = new Label
        {
            Text = caption,
            ForeColor = Muted,
            Font = Mono(8, FontStyle.Bold),
            AutoSize = true,
            Location = new Point(8, 5)
        };
        tile.Controls.Add(key);

        value.ForeColor = Cyan;
        value.Font = Mono(12, FontStyle.Bold);
        value.AutoSize = true;
        value.Location = new Point(8, 21);
        tile.Controls.Add(value);

        telemetry.Controls.Add(tile);
    }

    private void LayoutUi()
    {
        int w = ClientSize.Width;
        int h = ClientSize.Height;
        if (w <= 0 || h <= 0) return;

        int margin = Math.Max(24, w / 58);
        int headerW = Math.Min(860, w - margin * 2);
        header.SetBounds(margin, 22, headerW, 70);

        title.Location = new Point(28, 13);
        subtitle.Location = new Point(30, 40);

        exitButton.SetBounds(header.Width - 46, 14, 32, 38);
        settingsButton.SetBounds(header.Width - 86, 14, 32, 38);
        minimizeButton.SetBounds(header.Width - 126, 14, 32, 38);

        clock.Location = new Point(margin + 2, header.Bottom + 26);
        core.Location = new Point(margin + 365, header.Bottom + 50);
        date.Location = new Point(margin + 365, header.Bottom + 74);
        nodeCount.Location = new Point(margin + 4, header.Bottom + 119);

        telemetry.SetBounds(margin, header.Bottom + 145, Math.Min(540, w / 2), 56);
        int tileGap = 6;
        int tileW = (telemetry.Width - tileGap * 3) / 4;
        int i = 0;
        foreach (Control tile in telemetry.Controls)
        {
            tile.SetBounds(i * (tileW + tileGap), 0, tileW, 52);
            i++;
        }

        int corePanelW = Math.Clamp(w / 4, 260, 360);
        int corePanelH = 118;
        int corePanelX = margin;
        int corePanelY = telemetry.Bottom + 26;
        corePanel.SetBounds(corePanelX, corePanelY, corePanelW, corePanelH);
        corePanelTitle.Location = new Point(14, 12);
        corePanelInfo.Location = new Point(14, 38);
        coreActivityRail.SetBounds(14, corePanelH - 24, corePanelW - 28, 5);
        coreActivityFill.SetBounds(0, 0, Math.Max(1, (int)(coreActivityRail.Width * 0.72)), 5);

        quickModules.SetBounds(corePanelX, corePanel.Bottom + 12, Math.Min(450, w / 2), 36);

        int stackW = Math.Clamp(w / 4, 240, 320);
        int stackX = w - stackW - margin;
        int stackY = Math.Max(header.Bottom + 150, h / 3);
        nodeStack.SetBounds(stackX, stackY, stackW, 230);

        int primaryH = 44;
        int buttonH = 34;
        int gap = 7;
        accButton.SetBounds(0, 0, stackW, primaryH);
        waButton.SetBounds(0, primaryH + gap, stackW, buttonH);
        noteButton.SetBounds(0, primaryH + gap + (buttonH + gap), stackW, buttonH);
        fbButton.SetBounds(0, primaryH + gap + (buttonH + gap) * 2, stackW, buttonH);
        igButton.SetBounds(0, primaryH + gap + (buttonH + gap) * 3, stackW, buttonH);

        int statusY = Math.Min(h - 178, nodeStack.Bottom + 26);
        leftRail.Location = new Point(stackX + 4, statusY);
        commandText.Location = new Point(stackX + 42, statusY + 14);

        appsButton.SetBounds(w - margin - 132, h - 82, 132, 38);
        startupButton.SetBounds(margin, h - 62, 150, 30);
        taskbarButton.SetBounds(margin + 158, h - 62, 150, 30);
        footer.Location = new Point(Math.Max(margin + 330, (w - footer.Width) / 2), h - 55);

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

        double cpu = GetCpuUsage();
        cpuValue.Text = $"{cpu:0}%";

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

        bool network = NetworkInterface.GetIsNetworkAvailable();
        netValue.Text = network ? "ON" : "OFF";

        corePanelInfo.Text =
            $"CPU {cpu:0}%  //  NET {(network ? "LINK" : "OFF")}\r\n" +
            $"SHELL SAFE  //  {shortcuts.Count} NODES\r\n" +
            $"FASTLINK READY  //  LOCAL";

        if (coreActivityRail.Width > 0)
        {
            double fillRatio = Math.Clamp((cpu / 100d) * 0.6 + 0.25, 0.25, 0.92);
            coreActivityFill.Width = Math.Max(1, (int)(coreActivityRail.Width * fillRatio));
            coreActivityFill.BackColor = cpu >= 80 ? Magenta : Cyan;
        }
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

    private void LaunchChrome()
    {
        string[] candidates =
        [
            Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ProgramFiles), "Google", "Chrome", "Application", "chrome.exe"),
            Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ProgramFilesX86), "Google", "Chrome", "Application", "chrome.exe"),
            Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "Google", "Chrome", "Application", "chrome.exe")
        ];

        var exe = candidates.FirstOrDefault(File.Exists);
        if (exe != null)
        {
            OpenTarget(exe);
            return;
        }

        var hit = shortcuts.FirstOrDefault(s => s.Name.Contains("Chrome", StringComparison.OrdinalIgnoreCase));
        if (hit != null)
            LaunchShortcut(hit);
        else
            OpenTarget("https://www.google.com/");
    }

    private void LaunchSpotify()
    {
        try
        {
            Process.Start(new ProcessStartInfo("spotify:") { UseShellExecute = true });
        }
        catch
        {
            OpenTarget("https://open.spotify.com/");
        }
    }

    private void LaunchDiscord()
    {
        try
        {
            Process.Start(new ProcessStartInfo("discord:") { UseShellExecute = true });
        }
        catch
        {
            var hit = shortcuts.FirstOrDefault(s => s.Name.Contains("Discord", StringComparison.OrdinalIgnoreCase));
            if (hit != null)
                LaunchShortcut(hit);
            else
                OpenTarget("https://discord.com/app");
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
            MessageBox.Show(
                $"Tidak bisa membuka target.\n\n{ex.Message}",
                "ARDA OS",
                MessageBoxButtons.OK,
                MessageBoxIcon.Warning);
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

        var drawerMeta = new Label
        {
            Text = "SEARCH + LAUNCH  //  VISUAL NODE GRID",
            ForeColor = Muted,
            Font = Mono(8),
            AutoSize = true,
            Location = new Point(24, 40)
        };
        drawer.Controls.Add(drawerMeta);

        var close = new Button { Text = "×", Name = "DrawerClose" };
        ConfigureTinyButton(close, Magenta);
        close.Click += (_, _) => drawer.Visible = false;
        drawer.Controls.Add(close);

        appSearch = new TextBox
        {
            BorderStyle = BorderStyle.FixedSingle,
            BackColor = Panel2,
            ForeColor = UiText,
            Font = Mono(11),
            PlaceholderText = "SEARCH APPS...",
            Location = new Point(22, 66)
        };
        appSearch.TextChanged += (_, _) => RenderAppDrawer();
        drawer.Controls.Add(appSearch);

        appFlow = new FlowLayoutPanel
        {
            AutoScroll = true,
            WrapContents = true,
            FlowDirection = FlowDirection.LeftToRight,
            BackColor = Color.Transparent,
            Location = new Point(22, 118),
            Padding = new Padding(0, 0, 4, 12)
        };
        drawer.Controls.Add(appFlow);
    }

    private void LayoutDrawer()
    {
        if (drawer == null) return;

        int dw = Math.Clamp((int)(ClientSize.Width * 0.76), 760, 1120);
        int dh = Math.Clamp((int)(ClientSize.Height * 0.78), 520, 800);
        drawer.SetBounds((ClientSize.Width - dw) / 2, (ClientSize.Height - dh) / 2, dw, dh);

        var close = drawer.Controls.Find("DrawerClose", true).FirstOrDefault();
        close?.SetBounds(dw - 58, 14, 36, 36);

        appSearch?.SetBounds(22, 66, dw - 44, 36);
        appFlow?.SetBounds(22, 116, dw - 44, dh - 138);
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
            var card = new Panel
            {
                Width = 210,
                Height = 72,
                Margin = new Padding(5),
                BackColor = Color.FromArgb(200, Panel),
                Cursor = Cursors.Hand,
                Tag = item
            };
            card.Paint += (_, e) => DrawHudBorder(e.Graphics, card.ClientRectangle, Dim, dashed: false);

            var glyph = new Label
            {
                Text = "◈",
                ForeColor = item.Name.Contains("ACC", StringComparison.OrdinalIgnoreCase) ? Magenta : Cyan,
                Font = Mono(20, FontStyle.Bold),
                AutoSize = true,
                Location = new Point(12, 18)
            };
            card.Controls.Add(glyph);

            var appName = new Label
            {
                Text = item.Name,
                ForeColor = UiText,
                Font = Mono(9, FontStyle.Bold),
                AutoEllipsis = true,
                Location = new Point(48, 12),
                Size = new Size(150, 22)
            };
            card.Controls.Add(appName);

            var appMeta = new Label
            {
                Text = "START NODE  >",
                ForeColor = Muted,
                Font = Mono(8),
                Location = new Point(48, 39),
                Size = new Size(145, 18)
            };
            card.Controls.Add(appMeta);

            EventHandler launch = (_, _) => LaunchShortcut(item);
            card.Click += launch;
            glyph.Click += launch;
            appName.Click += launch;
            appMeta.Click += launch;

            card.MouseEnter += (_, _) => card.BackColor = Color.FromArgb(235, Panel2);
            card.MouseLeave += (_, _) => card.BackColor = Color.FromArgb(200, Panel);

            appFlow.Controls.Add(card);
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
            MessageBox.Show(
                $"Tidak bisa membuka {shortcut.Name}.\n\n{ex.Message}",
                "ARDA OS",
                MessageBoxButtons.OK,
                MessageBoxIcon.Warning);
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
            string sourceExe = Environment.ProcessPath ?? Application.ExecutablePath;
            string installDir = Path.Combine(
                Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
                "ARDA OS");
            Directory.CreateDirectory(installDir);

            string installedExe = Path.Combine(installDir, "ARDA-OS-Desktop.exe");

            try
            {
                if (!Path.GetFullPath(sourceExe).Equals(
                        Path.GetFullPath(installedExe),
                        StringComparison.OrdinalIgnoreCase))
                {
                    File.Copy(sourceExe, installedExe, overwrite: true);
                }

                key.SetValue("ARDA OS Desktop", $"\"{installedExe}\"");
            }
            catch
            {
                key.SetValue("ARDA OS Desktop", $"\"{sourceExe}\"");
            }
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
        bool enabled = IsStartupEnabled();
        startupButton.Text = enabled ? "AUTOSTART // ON" : "AUTOSTART // OFF";
        startupButton.ForeColor = enabled ? Cyan : Muted;
    }

    private void ToggleTaskbar()
    {
        taskbarHidden = !taskbarHidden;
        SetTaskbarVisible(!taskbarHidden);
        UpdateTaskbarText();
    }

    private void UpdateTaskbarText()
    {
        taskbarButton.Text = taskbarHidden ? "TASKBAR // HIDDEN" : "TASKBAR // VISIBLE";
        taskbarButton.ForeColor = taskbarHidden ? Magenta : Muted;
    }

    private static void SetTaskbarVisible(bool visible)
    {
        int command = visible ? SW_SHOW : SW_HIDE;

        IntPtr tray = FindWindow("Shell_TrayWnd", null);
        if (tray != IntPtr.Zero)
            ShowWindow(tray, command);

        IntPtr secondary = IntPtr.Zero;
        do
        {
            secondary = FindWindowEx(IntPtr.Zero, secondary, "Shell_SecondaryTrayWnd", null);
            if (secondary != IntPtr.Zero)
                ShowWindow(secondary, command);
        }
        while (secondary != IntPtr.Zero);
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

    private const int SW_HIDE = 0;
    private const int SW_SHOW = 5;

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern bool GetSystemTimes(
        out FILETIME idleTime,
        out FILETIME kernelTime,
        out FILETIME userTime);

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern bool GlobalMemoryStatusEx(ref MEMORYSTATUSEX lpBuffer);

    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    private static extern IntPtr FindWindow(string lpClassName, string? lpWindowName);

    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    private static extern IntPtr FindWindowEx(
        IntPtr parentHandle,
        IntPtr childAfter,
        string className,
        string? windowTitle);

    [DllImport("user32.dll")]
    private static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);

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
    private readonly System.Windows.Forms.Timer timer = new() { Interval = 58 };
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
        "CORE_PANEL::ONLINE   TASKBAR_SWITCH::READY",
        "QUICK_MODULES::FILES/CHROME/SPOTIFY/DISCORD",
        "CYBERDECK HUD DESKTOP v0.3   RIGHT STATUS ACTIVE"
    ];

    private float offset;

    public CodeStreamControl()
    {
        SetStyle(
            ControlStyles.UserPaint |
            ControlStyles.AllPaintingInWmPaint |
            ControlStyles.OptimizedDoubleBuffer |
            ControlStyles.ResizeRedraw,
            true);

        BackColor = Color.FromArgb(3, 7, 11);

        timer.Tick += (_, _) =>
        {
            offset -= 0.7f;
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
        e.Graphics.TextRenderingHint =
            System.Drawing.Text.TextRenderingHint.ClearTypeGridFit;

        using var cyan = new SolidBrush(Color.FromArgb(82, 42, 238, 255));
        using var magenta = new SolidBrush(Color.FromArgb(48, 255, 49, 153));
        using var scan = new Pen(Color.FromArgb(14, 100, 180, 190), 1f);

        float lineHeight = 26f;
        int count = (int)Math.Ceiling(Height / lineHeight) + 3;

        for (int i = 0; i < count; i++)
        {
            float y = offset + i * lineHeight;
            int idx = i % lines.Length;
            string prefix = $"{(i * 19 + 0x1A) & 0xFF:X2} ";

            e.Graphics.DrawString(
                prefix + lines[idx],
                font,
                cyan,
                12f,
                y);

            if (i % 4 == 2)
            {
                e.Graphics.DrawString(
                    ":: " + lines[(idx + 7) % lines.Length],
                    font,
                    magenta,
                    160f,
                    y + 10f);
            }
        }

        for (int y = 0; y < Height; y += 5)
            e.Graphics.DrawLine(scan, 0, y, Width, y);
    }
}
