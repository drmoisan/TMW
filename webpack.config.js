/* eslint-disable no-undef */

const webpack = require("webpack");
const devCerts = require("office-addin-dev-certs");
const CopyWebpackPlugin = require("copy-webpack-plugin");
const HtmlWebpackPlugin = require("html-webpack-plugin");

const urlDev = "https://localhost:3000/";
// Production static-asset base URL. Override via ADDIN_URL_PROD env var for mobile Dev Tunnel
// builds, e.g.: $env:ADDIN_URL_PROD = "https://taskmaster-ios.<cluster>.devtunnels.ms/"
const urlProd = process.env.ADDIN_URL_PROD ?? "https://www.contoso.com/";

async function getHttpsOptions() {
  const httpsOptions = await devCerts.getHttpsServerOptions();
  return { ca: httpsOptions.ca, key: httpsOptions.key, cert: httpsOptions.cert };
}

module.exports = async (env, options) => {
  const dev = options.mode === "development";
  const config = {
    devtool: "source-map",
    entry: {
      polyfill: ["core-js/stable", "regenerator-runtime/runtime"],
      taskpane: ["./src/taskpane/taskpane.ts", "./src/taskpane/taskpane.html"],
      ifile: ["./src/taskpane/ifile/ifile.ts", "./src/taskpane/ifile/ifile.html"],
      commands: "./src/commands/commands.ts",
    },
    output: {
      clean: true,
      // Content-hash only the iFile and taskpane entry chunks so a rebuilt JS bundle gets a new
      // URL the iOS Outlook web-view cache cannot match. commands.js MUST stay unhashed: both
      // manifest.json (CommandsRuntime code.script at https://localhost:3000/commands.js) and
      // manifest.xml reference commands.js by fixed name, so hashing it would break the manifest.
      // polyfill.js is a shared runtime chunk injected into the HTML pages; keeping it stable
      // avoids any manifest/runtime surprise.
      filename: (pathData) =>
        pathData.chunk &&
        (pathData.chunk.name === "ifile" || pathData.chunk.name === "taskpane")
          ? "[name].[contenthash].js"
          : "[name].js",
    },
    resolve: {
      extensions: [".ts", ".html", ".js"],
    },
    module: {
      rules: [
        {
          test: /\.ts$/,
          exclude: /node_modules/,
          use: {
            loader: "babel-loader"
          },
        },
        {
          test: /\.html$/,
          exclude: /node_modules/,
          use: "html-loader",
        },
        {
          test: /\.(png|jpg|jpeg|gif|ico)$/,
          type: "asset/resource",
          generator: {
            filename: "assets/[name][ext][query]",
          },
        },
      ],
    },
    plugins: [
      // Inject the API base URL at build time. Desktop dev builds use the default
      // (localhost:3000 / webpack dev-server). A MOBILE BUILD MUST set API_BASE_URL to a
      // reachable Dev-Tunnel/deployed host AND set the mobile-build flag IFILE_MOBILE_BUILD=1,
      // e.g.: $env:API_BASE_URL = "https://taskmaster-api.<cluster>.devtunnels.ms"; $env:IFILE_MOBILE_BUILD = "1".
      // The localhost default remains only for non-mobile desktop dev; a mobile build pointed at
      // localhost is rejected at runtime by assertReachableApiBaseUrl (src/taskpane/ifile/api-base-url.ts),
      // because localhost resolves to the device itself and the backend is unreachable. The actual
      // Dev-Tunnel URL is supplied at build time per the on-device verification runbook (HI-2); it is
      // never hardcoded here.
      new webpack.DefinePlugin({
        __API_BASE_URL__: JSON.stringify(
          process.env.API_BASE_URL ?? "https://localhost:3000"
        ),
        __IS_MOBILE_BUILD__: JSON.stringify(
          process.env.IFILE_MOBILE_BUILD === "1" || process.env.IFILE_MOBILE_BUILD === "true"
        ),
        // On-screen build stamp so the developer can confirm on-device which build is loaded.
        // This file is build tooling, not runtime code under the determinism rules, so new Date()
        // here is acceptable; BUILD_ID overrides it with a reproducible value when set.
        __BUILD_ID__: JSON.stringify(process.env.BUILD_ID ?? new Date().toISOString()),
      }),
      new HtmlWebpackPlugin({
        filename: "taskpane.html",
        template: "./src/taskpane/taskpane.html",
        chunks: ["polyfill", "taskpane"],
      }),
      new CopyWebpackPlugin({
        patterns: [
          {
            from: "assets/*",
            to: "assets/[name][ext][query]",
          },
          {
            from: "manifest*.{json,xml}",
            to: "[name]" + "[ext]",
            transform(content) {
              if (dev) {
                return content;
              } else {
                return content.toString().replace(new RegExp(urlDev, "g"), urlProd);
              }
            },
          },
        ],
      }),
      new HtmlWebpackPlugin({
        filename: "ifile.html",
        template: "./src/taskpane/ifile/ifile.html",
        chunks: ["polyfill", "ifile"],
      }),
      new HtmlWebpackPlugin({
        filename: "commands.html",
        template: "./src/commands/commands.html",
        chunks: ["polyfill", "commands"],
      }),
    ],
    devServer: {
      headers: {
        "Access-Control-Allow-Origin": "*",
      },
      server: {
        type: "https",
        options: env.WEBPACK_BUILD || options.https !== undefined ? options.https : await getHttpsOptions(),
      },
      port: process.env.npm_package_config_dev_server_port || 3000,
    },
  };

  return config;
};
