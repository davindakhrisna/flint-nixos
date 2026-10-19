{
  lib,
  fetchurl,
  jq,
  nodejs,
  writeTextFile,
  dsh,
}:
dsh.helpers.buildBundle (_: {
  pname = "dsh-agy-safe";
  version = "0.1.8";
  src = fetchurl {
    url = "https://registry.npmjs.org/dsh-agy-safe/-/dsh-agy-safe-0.1.8.tgz";
    hash = "sha512-idpTBewlL8eNutk78JouN3iNcel+GY0KFTCDd/nxGlJIYSY8gOAmBAkcCBiFHAHjlEMaf2Dvk16HuN++EyVgmQ==";
  };
  nativeBuildInputs = [jq nodejs];
  linkKernelNodeModules = dsh.dsh-kernel;
  postPatch = ''
    jq 'del(.scripts, .dependencies, .devDependencies, .peerDependencies, .peerDependenciesMeta)' \
      package.json > package.json.tmp
    mv package.json.tmp package.json
    substituteInPlace lib/index.js \
      --replace-fail "export const inject = ['llm', 'webServer', 'settings'];" "export const inject = ['llm'];"

    substituteInPlace lib/login.js \
      --replace-fail "const child = spawn('x-terminal-emulator', ['-e', agyPath], {" \
                     "return { started: false, error: \"Please run 'agy login' in your local terminal.\" }; const child = spawn('x-terminal-emulator', ['-e', agyPath], {" \
      --replace-fail "export function isSameOriginRequest(req) {" \
                     "export function isSameOriginRequest(req) { return true;"

    substituteInPlace lib/client.js \
      --replace-fail "无法连接宿主接口: " "Failed to connect to host: " \
      --replace-fail "已在桌面弹出系统终端，请在终端窗口完成 Antigravity 登录。" "Terminal opened. Please complete login in the terminal." \
      --replace-fail "无法自动弹出终端，请手动在终端中运行 agy 进行登录。" "Could not launch terminal automatically. Please run agy login in your terminal." \
      --replace-fail "启动登录终端失败: " "Failed to launch login terminal: " \
      --replace-fail "正在向 Antigravity CLI 发送验证请求..." "Sending verification request to Antigravity CLI..." \
      --replace-fail "凭据验证通过！Antigravity CLI 模型可正常调用。" "Credentials verified successfully! Antigravity CLI models are ready to use." \
      --replace-fail "凭据验证未通过: " "Credentials verification failed: " \
      --replace-fail "未登录或会话已过期" "Not logged in or session expired" \
      --replace-fail "验证调用失败: " "Verification call failed: " \
      --replace-fail "Antigravity CLI (agy) 提供商设置" "Antigravity CLI (agy) Provider Settings" \
      --replace-fail "将本机已登录的 Antigravity CLI (agy) 无头会话作为 DeepSeek Harness 的模型后端，主会话模型与子代理模型通用。" "Use local authenticated Antigravity CLI (agy) headless sessions as the model backend for chat and subagents." \
      --replace-fail "'安装状态'" "'Status'" \
      --replace-fail "已安装 (" "Installed (" \
      --replace-fail "未知版本" "unknown version" \
      --replace-fail "未检测到 agy" "agy not detected" \
      --replace-fail "'程序路径'" "'Binary Path'" \
      --replace-fail "'沙盒缓存目录'" "'Scratch Directory'" \
      --replace-fail "'本地凭据缓存'" "'Credentials Cache'" \
      --replace-fail "已检测到凭据目录 (~/.gemini)" "Credentials directory detected (~/.gemini)" \
      --replace-fail "未检测到凭据" "No credentials detected" \
      --replace-fail "打开登录终端" "Open Login Terminal" \
      --replace-fail "验证登录凭据" "Verify Credentials" \
      --replace-fail "正在验证..." "Verifying..." \
      --replace-fail "刷新状态" "Refresh Status" \
      --replace-fail "刷新中..." "Refreshing..."

    node --check lib/*.js
  '';
  npmConfigHook = writeTextFile {
    name = "noop-npm-config-hook";
    destination = "/nix-support/setup-hook";
    text = "";
  };
  npmDeps = null;
  dontBuild = true;
  dontNpmBuild = true;
  dontNpmInstall = true;
  installPhase = ''
    runHook preInstall
    mkdir -p "$out/lib/node_modules/dsh-agy-safe"
    cp -r * "$out/lib/node_modules/dsh-agy-safe/"
    runHook postInstall
  '';
  meta = {
    description = "Use a logged-in Antigravity CLI (agy) headless session as the chat and subagent model provider";
    license = lib.licenses.mit;
  };
})
