const spawnSync = require("child_process").spawnSync;

const { CHAPTEREXE_COMMAND, CHAPTEREXE_OUTPUT } = require("../settings");

exports.exec = filename => {
  const args = ["-v", filename, "-s", "8", "-e", "4", "-o", CHAPTEREXE_OUTPUT];
  try {
    spawnSync(CHAPTEREXE_COMMAND, args, { stdio: "inherit" });
  } catch (e) {
    console.error(e);
    process.exit(-1);
  }
};
