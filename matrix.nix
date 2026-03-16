{ config, lib, ... }:
let
  cfg = config.services.matrix-tuwunel;
in
{
  networking.firewall = {
    allowedTCPPorts = [
      80 # http
      443 # https
      8448 # matrix
      5349 # coturn
      7881 # livekit
      3478 # coturn
    ];
    allowedTCPPortRanges = [
      {
        from = 50200;
        to = 50399;
      }
    ];
    allowedUDPPorts = [
      5349
      3478
    ];
    allowedUDPPortRanges = [
      {
        from = 50200;
        to = 50399;
      }
    ];
  };
  security.acme = {
    acceptTerms = true;
    certs."oursa.cc" = {
      email = "GregLeyda@proton.me";
      inherit (config.services.nginx) group;
      webroot = "/var/lib/acme/acme-challenge";
      extraDomainNames = [
        "matrix-rtc.oursa.cc"
        "coturn.oursa.cc"
      ];
    };
  };

  services.matrix-tuwunel = {
    enable = true;
    settings = {
      global = {
        port = [ 6167 ];
        server_name = "oursa.cc";
        new_user_displayname_suffix = "";
        max_request_size = 1000 * 1000 * 100 * 20;

        allow_registration = true;
        registration_token_file = config.sops.secrets.matrix_reg.path;
        grant_admin_to_first_user = true;

        allow_encryption = true;
        allow_federation = true;

        trusted_servers = [
          "matrix.org"
          "nixos.org"
          "libera.chat"
          "conduit.rs"
        ];
        turn_uris = [
          "turns:coturn.oursa.cc?transport=udp"
          "turns:coturn.oursa.cc?transport=tcp"
          "turn:coturn.oursa.cc?transport=udp"
          "turn:coturn.oursa.cc?transport=tcp"
        ];
        turn_secret_file = config.sops.secrets.tuwunel.path;
        well_known = {
          client = "https://oursa.cc";
          server = "oursa.cc:443";
          rtc_transports = [
            {
              type = "livekit";
              livekit_service_url = "https://matrix-rtc.oursa.cc";
            }
          ];
        };
      };
    };
  };
  services.livekit = {
    enable = true;
    keyFile = config.sops.secrets.livekit.path;
    openFirewall = true;
    settings = {
      port = 7880;
      rtc = {
        tcp_port = 7881;
        use_external_ip = true;
        port_range_start = 50000;
        port_range_end = 50199;
        enable_loopback_candidate = false;
        turn_servers = [
          {
            host = "coturn.oursa.cc";
            port = 5349;
            protocol = "udp";
            secret = "b0MTWrB2f9iuQ8VNY8kJ0Yh3J3RFUlLPwr2AmDtIu9PjDlMwlW3Ekq68nw1WoYnA";
          }
        ];
      };
      turn = {
        enabled = false;
        #udp_port = 5349;
        #domain = "coturn.oursa.cc";
        #relay_range_start = 50200;
        #relay_range_end = 50399;
      };
    };
  };
  services.lk-jwt-service = {
    enable = true;
    port = 8080;
    keyFile = config.sops.secrets.livekit.path;
    livekitUrl = "wss://matrix-rtc.oursa.cc";
  };
  services.coturn = {
    enable = true;
    tls-listening-port = 5349;
    use-auth-secret = true;
    static-auth-secret-file = config.sops.secrets.coturn.path;
    realm = "coturn.oursa.cc";
    min-port = 50200;
    max-port = 50399;
  };

  services.nginx = {
    enable = true;
    experimentalZstdSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    clientMaxBodySize = "1G";
    proxyTimeout = "600s";
    virtualHosts = {
      "oursa.cc" = {
        useACMEHost = "oursa.cc";
        listen = [
          {
            addr = "0.0.0.0";
            port = 80;
          }
          {
            addr = "[::0]";
            port = 80;
          }
          {
            addr = "0.0.0.0";
            port = 443;
            ssl = true;
          }
          {
            addr = "[::0]";
            port = 443;
            ssl = true;
          }
          {
            addr = "0.0.0.0";
            port = 8448;
            ssl = true;
          }
          {
            addr = "[::0]";
            port = 8448;
            ssl = true;
          }
        ];

        forceSSL = true;
        extraConfig = ''
          merge_slashes off;
        '';

        locations = {
          "/_matrix" = {
            proxyPass = "http://127.0.0.1:${toString (lib.head cfg.settings.global.port)}";
            proxyWebsockets = true;
            extraConfig = ''
              proxy_set_header Host $host;
              proxy_buffering off;
              proxy_read_timeout 5m;
            '';
          };
          "/.well-known/matrix" = {
            proxyPass = "http://127.0.0.1:${toString (lib.head cfg.settings.global.port)}";
          };
        };
      };

      "matrix-rtc.oursa.cc" = {
        useACMEHost = "oursa.cc";
        forceSSL = true;
        locations = {
          "~ ^/(sfu/get|healthz|get_token)" = {

            proxyPass = "http://127.0.0.1:${toString config.services.lk-jwt-service.port}";
            priority = 400;
            extraConfig = ''
              proxy_set_header X-Forwarded-For $remote_addr;
              proxy_set_header X-Real-IP $remote_addr;
              proxy_set_header $host $http_host;
              proxy_buffering off;            
            '';
          };
          "/" = {
            proxyPass = "http://127.0.0.1:${toString config.services.livekit.settings.port}";
            extraConfig = ''
              proxy_send_timeout 120;
              proxy_read_timeout 120;
              proxy_buffering off;

              proxy_set_header X-Forwarded-For $remote_addr;
              proxy_set_header X-Real-IP $remote_addr;
              proxy_set_header $host $http_host;

              proxy_set_header Accept-Encoding gzip;
              proxy_set_header Upgrade $http_upgrade;
              proxy_set_header Connection "upgrade";
            '';
            priority = 400;
            proxyWebsockets = true;
          };
        };
      };
      "coturn.oursa.cc" = {
        useACMEHost = "oursa.cc";
        forceSSL = true;
        locations."/".proxyPass = "http://127.0.0.1:${toString config.services.coturn.listening-port}";
      };
    };
  };

  sops.secrets = {
    livekit = { };
    livekitEnv = { };
    tuwunel.owner = "tuwunel";
    coturn.owner = "turnserver";
    matrix_reg.owner = config.services.matrix-tuwunel.user;
  };
}
