const spawnSync = require("child_process").spawnSync;
const path = require("path");
const fs = require("fs-extra");

const {
  LOGOFRAME_COMMAND,
  LOGO_PATH,
  LOGOFRAME_OUTPUT
} = require("../settings");

const getLogo = logoName => {
  let logo = path.join(LOGO_PATH, `${logoName}.lgd`);
  if (fs.existsSync(logo)) {
    return logo;
  }

  logo = path.join(LOGO_PATH, `${logoName}.lgd2`);
  if (fs.existsSync(logo)) {
    return logo;
  }
  return null;
};

const selectLogo = channel => {
  if (!channel) {
    return null;
  }

  for (key of ["install", "short", "recognize"]) {
    const logo = getLogo(channel[key]);
    if (logo) {
      return logo;
    }
  }

  return null;
};

exports.exec = (param, channel, filename) => {
  const args = [filename, "-oa", LOGOFRAME_OUTPUT];

  const logo = selectLogo(channel);
  let logosub = null;
  if (param.LOGOSUBHEAD) {
    logosub = getLogo(param.LOGOSUBHEAD);
  }

  if (!logosub && !logo) {
    return;
  }

  if (logo) {
    args.push("-logo");
    args.push(logo);
  }

  if (logosub) {
    args.push("-logo99");
    args.push(logosub);
  }
  try {
    spawnSync(LOGOFRAME_COMMAND, args, { stdio: "inherit" });
  } catch (e) {
    console.error(e);
    process.exit(-1);
  }
};
