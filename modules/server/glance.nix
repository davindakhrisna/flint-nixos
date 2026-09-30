_: {
  flake.nixosModules.glance = {pkgs, ...}: let
    dashboardAssets = pkgs.linkFarm "glance-assets" [
      {
        name = "glance.css";
        path = ./config/glance.css;
      }
    ];
  in {
    services.glance = {
      enable = true;
      settings = {
        server = {
          port = 8080;
          host = "127.0.0.1";
          assets-path = toString dashboardAssets;
        };
        branding = {
          app-name = "Homelab";
          custom-footer = "flint · private";
        };
        theme = {
          background-color = "0 0 3";
          primary-color = "0 0 92";
          positive-color = "0 0 72";
          negative-color = "0 0 48";
          contrast-multiplier = 1.2;
          text-saturation-multiplier = 0;
          custom-css-file = "/assets/glance.css";
          disable-picker = true;
        };
        pages = [
          {
            name = "Home";
            slug = "home";
            width = "wide";
            show-mobile-header = true;
            head-widgets = [
              {
                type = "search";
                search-engine = "duckduckgo";
                placeholder = "Search the web or use !gh, !nix, !yt";
                bangs = [
                  {
                    title = "GitHub";
                    shortcut = "!gh";
                    url = "https://github.com/search?q={QUERY}";
                  }
                  {
                    title = "Nix packages";
                    shortcut = "!nix";
                    url = "https://search.nixos.org/packages?query={QUERY}";
                  }
                  {
                    title = "YouTube";
                    shortcut = "!yt";
                    url = "https://www.youtube.com/results?search_query={QUERY}";
                  }
                ];
              }
            ];
            columns = [
              {
                size = "small";
                widgets = [
                  {
                    type = "weather";
                    location = "Surabaya, Indonesia";
                    hour-format = "24h";
                    units = "metric";
                  }
                  {
                    type = "clock";
                    hour-format = "24h";
                    timezones = [
                      {
                        timezone = "Asia/Jakarta";
                        label = "HOME";
                      }
                    ];
                  }
                  {
                    type = "calendar";
                    first-day-of-week = "monday";
                  }
                ];
              }
              {
                size = "full";
                widgets = [
                  {
                    type = "server-stats";
                    css-class = "infrastructure-card";
                    servers = [
                      {
                        type = "local";
                        name = "homelab";
                        hide-mountpoints-by-default = true;
                        mountpoints = {
                          "/" = {
                            name = "System";
                            hide = false;
                          };
                          "/home" = {
                            name = "Home";
                            hide = false;
                          };
                          "/persist" = {
                            name = "Persistent state";
                            hide = false;
                          };
                        };
                      }
                    ];
                  }
                  {
                    type = "monitor";
                    title = "Applications";
                    cache = "30s";
                    sites = [
                      {
                        title = "Immich";
                        url = "https://\${HOMELAB_HOST}:8443";
                        check-url = "http://127.0.0.1:2283";
                        icon = "sh:immich";
                        same-tab = true;
                      }
                      {
                        title = "Vaultwarden";
                        url = "https://\${HOMELAB_HOST}:8444";
                        check-url = "http://127.0.0.1:8222";
                        icon = "sh:vaultwarden";
                        same-tab = true;
                      }
                      {
                        title = "Obsidian Sync";
                        url = "https://\${HOMELAB_HOST}:8446/_utils";
                        check-url = "http://127.0.0.1:5984";
                        icon = "si:obsidian";
                        same-tab = true;
                      }
                      {
                        title = "Headroom";
                        url = "https://\${HOMELAB_HOST}:8448";
                        check-url = "http://127.0.0.1:8787/health";
                        icon = "mdi:brain";
                        same-tab = true;
                      }
                      {
                        title = "Hermes Agent";
                        url = "https://\${HOMELAB_HOST}:8449";
                        check-url = "http://127.0.0.1:9120";
                        icon = "mdi:robot";
                        same-tab = true;
                      }
                      {
                        title = "Audiobookshelf";
                        url = "https://\${HOMELAB_HOST}:8450";
                        check-url = "http://127.0.0.1:8000/ping";
                        icon = "sh:audiobookshelf";
                        same-tab = true;
                      }
                      {
                        title = "qBittorrent";
                        url = "https://\${HOMELAB_HOST}:8451";
                        check-url = "http://127.0.0.1:8090";
                        icon = "sh:qbittorrent";
                        same-tab = true;
                      }
                      {
                        title = "Jackett";
                        url = "https://\${HOMELAB_HOST}:8452";
                        check-url = "http://127.0.0.1:9117";
                        icon = "sh:jackett";
                        same-tab = true;
                      }
                    ];
                  }
                  {
                    type = "hacker-news";
                    title = "Hacker News // Signal";
                    limit = 10;
                    collapse-after = 10;
                    sort-by = "hot";
                    css-class = "hacker-news-signal";
                  }
                ];
              }
            ];
          }
        ];
      };
    };
  };
}
