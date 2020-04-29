const path = require("path");
const uuid = require("uuid/v4")();

exports.CHANNEL_LIST = path.join(__dirname, "../setting/ChList.csv");
exports.PARAM_LIST_1 = path.join(__dirname, "../setting/JLparam_set1.csv");
exports.PARAM_LIST_2 = path.join(__dirname, "../setting/JLparam_set2.csv");

exports.LOGOFRAME_COMMAND = path.join(__dirname, "../bin/logoframe");
exports.CHAPTEREXE_COMMAND = path.join(__dirname, "../bin/chapter_exe");
exports.JLSCP_COMMAND = path.join(__dirname, "../bin/join_logo_scp");
exports.FFPROBE_COMMAND = "/usr/local/bin/ffprobe";

exports.JL_DIR = path.join(__dirname, "../JL");
exports.LOGO_PATH = path.join(__dirname, "../logo");

exports.LOGOFRAME_OUTPUT = path.join(
  __dirname,
  `../tmp/obs_${uuid}_logoframe.txt`
);
exports.CHAPTEREXE_OUTPUT = path.join(
  __dirname,
  `../tmp/obs_${uuid}_chapterexe.txt`
);
exports.JLSCP_OUTPUT = path.join(__dirname, `../tmp/obs_${uuid}_jlscp.txt`);
exports.INPUT_AVS = path.join(__dirname, `../tmp/obs_${uuid}_input.avs`);
