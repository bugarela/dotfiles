{ pkgs, ...}:

let
  unstable = import <nixpkgs-unstable> { config.allowUnfree = true; };
in
{
  programs.vscode = {
    enable = true;
    userSettings = builtins.readFile ./settings.json;
    package = unstable.vscode-fhs;
    extensions = map
      (extension: pkgs.vscode-utils.buildVscodeMarketplaceExtension {
        mktplcRef = {
         inherit (extension) name publisher version sha256;
        };
      })[
      {
        name = "vscode-theme-onelight";
        publisher = "akamud";
        version = "2.3.0";
        sha256 = "198fhna68aqpmln0wvjwqyvfznjjyp9ykar1b2zjhc2id6rz8c09";
      }
      {
        name = "vscode-tlaplus";
        publisher = "alygin";
        version = "1.5.4";
        sha256 = "0mf98244z6wzb0vj6qdm3idgr2sr5086x7ss2khaxlrziif395dx";
      }
      {
        name = "Nix";
        publisher = "bbenoist";
        version = "1.0.1";
        sha256 = "0zd0n9f5z1f0ckzfjr38xw2zzmcxg1gjrava7yahg5cvdcw6l35b";
      }
      {
        name = "file-browser";
        publisher = "bodil";
        version = "0.2.11";
        sha256 = "1yi5i9qpbgc5bxx85vdakni72a7v4iwpsz1yhvjijrqlq2363xf8";
      }
      {
        name = "codebook";
        publisher = "codebook";
        version = "0.4.3";
        sha256 = "1cacaqh93qgimb14w3k6a8cw9a190sn9r7hn6df162mdbxnkgkxw";
      }
      {
        name = "vscode-markdownlint";
        publisher = "DavidAnson";
        version = "0.49.0";
        sha256 = "0mnk9bkiqqrgb97f4kw558ciffqlk1h2pv5x2abldmxq2ahww7rj";
      }
      {
        name = "vscode-eslint";
        publisher = "dbaeumer";
        version = "2.4.0";
        sha256 = "02q5g5p2vy7yxm2l89zvlkfx4rkdyzrrjaa97gl5sf6g88k11igc";
      }
      {
        name = "EditorConfig";
        publisher = "EditorConfig";
        version = "0.16.4";
        sha256 = "0fa4h9hk1xq6j3zfxvf483sbb4bd17fjl5cdm3rll7z9kaigdqwg";
      }
      {
        name = "vsc-community-material-theme";
        publisher = "Equinusocio";
        version = "1.4.6";
        sha256 = "0v34vm3asnw2maf4yz6lmn9xzv9232lm1a9vayybj1w0s09k4n0d";
      }
      {
        name = "prettier-vscode";
        publisher = "esbenp";
        version = "9.12.0";
        sha256 = "0nplxds28f9s3ny0xg2w6h6gsq5nfa5x7292hxm00radh9himcbg";
      }
      {
        name = "copilot-nightly";
        publisher = "GitHub";
        version = "1.84.53";
        sha256 = "17wpyxcdb359pf8pnrvz273zd5mz2jj6a9iqy2yv4ldmaggrx95z";
      }
      {
        name = "github-vscode-theme";
        publisher = "GitHub";
        version = "6.3.4";
        sha256 = "0csh0fai28jx32zdhlfvf9ml34760hq35q8g6slzvdzip03k9ci5";
      }
      {
        name = "vscode-pull-request-github";
        publisher = "GitHub";
        version = "0.63.2023042509";
        sha256 = "17ji868al2akc5rlq1dj04gyks0i4qr4z15lp5kcifgwd4p6b072";
      }
      {
        name = "haskell";
        publisher = "haskell";
        version = "2.2.4";
        sha256 = "1qsvfb2a2k48gndda92w91z9acis43a151cdwmkmb8qprl311768";
      }
      {
        name = "nord-light";
        publisher = "huytd";
        version = "0.1.1";
        sha256 = "13zvk5l5d4n8vjkn36r62n98n0nbcpxfz2ad2z325p337vg8cqdb";
      }
      {
        name = "itf-trace-viewer";
        publisher = "informal";
        version = "0.0.5";
        sha256 = "1znya0phd8j3is1188lxwa90hy8v7bxd95mdzv6d60li5q23rrzp";
      }
      {
        name = "quint-vscode";
        publisher = "informal";
        version = "0.3.0";
        sha256 = "079lynwdwkacpkm0wxjckqjn5afizlykrx6v6dy4pqd3xha1hnxi";
      }
      {
        name = "fuzzy-search";
        publisher = "jacobdufault";
        version = "0.0.3";
        sha256 = "0hvg4ac4zdxmimfwab1lzqizgq8bjfq6rksc9n7953m9gk6m5pd0";
      }
      {
        name = "nix-ide";
        publisher = "jnoortheen";
        version = "0.2.1";
        sha256 = "0bibb3r4cb7chnx6vpyl41ig12pc0cbg0sb8f2khs52c71nk4bn8";
      }
      {
        name = "language-haskell";
        publisher = "justusadam";
        version = "3.6.0";
        sha256 = "115y86w6n2bi33g1xh6ipz92jz5797d3d00mr4k8dv5fz76d35dd";
      }
      {
        name = "magit";
        publisher = "kahole";
        version = "0.6.40";
        sha256 = "1dvngm5cvn7dvg570palq9f86jxrji79qx8k9nhmw0k5l1y26283";
      }
      {
        name = "vscode-antlr4";
        publisher = "mike-lischke";
        version = "2.3.1";
        sha256 = "1sbkdg2bp0jgihmib36zfcvkcjgh1j3chphhs5ly7754mla09x7a";
      }
      {
        name = "isort";
        publisher = "ms-python";
        version = "2023.9.11141005";
        sha256 = "1hk75jpwl4v7910f5dw0zwb33bij1a76jpishv23dm81dd5g3s9p";
      }
      {
        name = "cmake-tools";
        publisher = "ms-vscode";
        version = "1.15.1";
        sha256 = "1bzakc44c74vxv8jlck0csdmzyk1whm4yz577arf5bks0dhvvcgz";
      }
      {
        name = "cpptools-extension-pack";
        publisher = "ms-vscode";
        version = "1.3.0";
        sha256 = "11fk26siccnfxhbb92z6r20mfbl9b3hhp5zsvpn2jmh24vn96x5c";
      }
      {
        name = "cpptools-themes";
        publisher = "ms-vscode";
        version = "2.0.0";
        sha256 = "05r7hfphhlns2i7zdplzrad2224vdkgzb0dbxg40nwiyq193jq31";
      }
      {
        name = "makefile-tools";
        publisher = "ms-vscode";
        version = "0.8.0";
        sha256 = "1iaijc6frpfsgiaxzb9zlzil7iyfdyh21sx10m7kij712rq7l7z8";
      }
      {
        name = "theme-quietlight-vsc";
        publisher = "onecrayon";
        version = "1.1.0";
        sha256 = "0z8h8ym3px2381wkq0lpr9lwwgmqqfz7bgcddrcwxnlkxb65qi1n";
      }
      {
        name = "languagetool";
        publisher = "raymondcamden";
        version = "1.0.1";
        sha256 = "0r3m7f1684sgaz348sh7d46k2v3asp2qzn3habhlrl148r6s08a9";
      }
      {
        name = "format-code-action";
        publisher = "rohit-gohri";
        version = "0.1.0";
        sha256 = "1b1z49vjmqmpdxpgknp015rir0jnqa6z8nm8h4lxip3wa9jizbcg";
      }
      {
        name = "vscode-direnv";
        publisher = "Rubymaniac";
        version = "0.0.2";
        sha256 = "1gml41bc77qlydnvk1rkaiv95rwprzqgj895kxllqy4ps8ly6nsd";
      }
      {
        name = "scala";
        publisher = "scala-lang";
        version = "0.5.6";
        sha256 = "004zc3id5jk8hk6q27g4p36prvnlqdsgda0gd6xvs4gamhywhb3s";
      }
      {
        name = "rewrap";
        publisher = "stkb";
        version = "17.8.0";
        sha256 = "1y168ar01zxdd2x73ddsckbzqq0iinax2zv3d95nhwp9asjnbpgn";
      }
      {
        name = "pdf";
        publisher = "tomoki1207";
        version = "1.2.2";
        sha256 = "16rs255x569ahxldw8ra799w078h97aa2b11j97ipqgh6s5nax4b";
      }
      {
        name = "cmake";
        publisher = "twxs";
        version = "0.0.17";
        sha256 = "11hzjd0gxkq37689rrr2aszxng5l9fwpgs9nnglq3zhfa1msyn08";
      }
      {
        name = "vim";
        publisher = "vscodevim";
        version = "1.25.2";
        sha256 = "0j0li3ddrknh34k2w2f13j4x8s0lb9gsmq7pxaldhwqimarqlbc7";
      }
      {
        name = "codetour";
        publisher = "vsls-contrib";
        version = "0.0.59";
        sha256 = "1mp860xsqws4pdy9lc2229iszkd2ri0lzxmwqacba73mw9300rvl";
      }
      {
        name = "vspacecode";
        publisher = "VSpaceCode";
        version = "0.10.14";
        sha256 = "0v8nk86zxj1iakrvmk656541r2byvnvchcqsdb6kdhznyfdp0cc9";
      }
      {
        name = "whichkey";
        publisher = "VSpaceCode";
        version = "0.11.3";
        sha256 = "0zix87vl2rig8wn3f6f3n6zdi0c61za3lw7xgm28sjhwwb08wxiy";
      }
      {
        name = "gitblame";
        publisher = "waderyan";
        version = "10.2.0";
        sha256 = "0iq2dlgkj7wqwdafcsg8acf3s5rcpfps82i5aj8qvjwv0xqrxyy3";
      }
      {
        name = "pretty-ts-errors";
        publisher = "yoavbls";
        version = "0.3.0";
        sha256 = "1czhfvv5zal27m8krkclh533a1kmg5k7va82qsgjm1bqmsm4baq2";
      }
      {
        name = "markdown-all-in-one";
        publisher = "yzhang";
        version = "3.5.1";
        sha256 = "04b8hiha6z7w189lkx0lhy0sgldrfwx1yikl2463lkhhkm3f8av7";
      }
    ];
  };
}
