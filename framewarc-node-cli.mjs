#!/usr/bin/env node

import $path from "path";
import $url from "url";

import commander from "commander";
import fse from "fs-extra";

const pkg = await fse.readJson("./package.json", "utf8");

const __dirname = $path.dirname($url.fileURLToPath(import.meta.url));


const program = new commander.Command();
program.version(pkg.version);
program.enablePositionalOptions();

program.command("copy-into <dir>")
    .allowExcessArguments(false)
    .description(
        "copy Framewarc's Arc files into `dir`, typically " +
        "<Arc host dir>/lib/framewarc/")
    .action(dir => fse.copy($path.join(__dirname, "arc"), dir));

await program.parseAsync();
