const csv = require("csv/lib/sync");
const fs = require("fs");
const path = require("path");

const { PARAM_LIST_1, PARAM_LIST_2 } = require("./settings");

const search = (paramList, channel, filename) => {
  const result = {};
  const short = channel ? channel.short : "__normal";

  for (param of paramList) {
    // コメント行は処理しない
    if (param.channel.match(/^#/)) {
      continue;
    }

    // 放送局の一致確認
    let regexp = new RegExp(`^(?=.*${param.channel})`);
    const matchChennel = short.match(regexp);

    // タイトルの一致確認
    regexp = new RegExp(`^(?=.*${param.title})`);
    const matchTitle = filename.match(regexp);

    if (matchChennel && matchTitle) {
      for (key of Object.keys(param)) {
        if (param[key] === "@") {
          result[key] = "";
        } else if (param[key] !== "") {
          result[key] = param[key];
        }
      }
    }
  }

  return result;
};

exports.parse = (channel, filepath) => {
  let result = {};

  for (file of [PARAM_LIST_1, PARAM_LIST_2]) {
    const data = fs.readFileSync(file);
    const paramList = csv.parse(data, {
      from: 2,
      columns: [
        "channel",
        "title",
        "JLOGO_CMD",
        "JL_FLAGS",
        "JLOGO_OPT1",
        "JLOGO_OPT2",
        "JLOGO_NOLOGO",
        "LOGOSUBHEAD",
        "use_tssplit",
        "use_intools",
        "tffbff",
        "comment1",
        "comment2"
      ]
    });
    const param = search(paramList, channel, path.basename(filepath));
    result = Object.assign(result, param);
  }

  return result;
};
