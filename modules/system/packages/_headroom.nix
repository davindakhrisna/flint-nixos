{
  fetchFromGitHub,
  lib,
  python3Packages,
  rustPlatform,
}:
python3Packages.buildPythonApplication (finalAttrs: {
  pname = "headroom-ai";
  version = "0.39.1";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "headroomlabs-ai";
    repo = "headroom";
    tag = "v${finalAttrs.version}";
    hash = "sha256-pcsKKq27cKyB7uWskbnWP8VI/UU9RdrE89QClLisvcU=";
  };

  cargoDeps = rustPlatform.fetchCargoVendor {
    inherit (finalAttrs) pname version src;
    hash = "sha256-azHjTfjdARzYuDMdH1AOYn0YV9U9lzaoULcSC/a9MuE=";
  };

  postPatch = ''
    substituteInPlace headroom/ccr/mcp_server.py \
      --replace-fail \
        "return HeadroomMCPServer(proxy_url=proxy_url)" \
        'return HeadroomMCPServer(proxy_url=proxy_url, check_proxy=os.environ.get("HEADROOM_MCP_CHECK_PROXY", "1").lower() not in ("0", "false", "off"))'
  '';

  build-system = with rustPlatform; [
    cargoSetupHook
    maturinBuildHook
  ];

  dependencies = with python3Packages; [
    ast-grep-cli
    click
    httpx
    litellm
    mcp
    opentelemetry-api
    pydantic
    pyyaml
    rich
    starlette
    tiktoken
    tomlkit
    uvicorn
  ];

  pythonImportsCheck = ["headroom"];

  meta = {
    description = "Local context compression tools for LLM applications";
    homepage = "https://github.com/headroomlabs-ai/headroom";
    license = lib.licenses.asl20;
    mainProgram = "headroom";
  };
})
