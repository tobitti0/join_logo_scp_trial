const fs = require("fs-extra");
const path = require("path");

const argv = require("yargs")
  .option("input", {
    alias: "i",
    type: "string",
    describe: "path to ts file"
  })
  .option("filter", {
    alias: "f",
    type: "string",
    describe: "path to ffmpeg filter output"
  })
  .option("avs", {
    alias: "a",
    type: "string",
    describe: "path to avs output"
  })
  .demandOption(
    ["input", "filter", "avs"],
    "Please provide input, filter and avs arguments to work with this tool"
  )
  .check(function(argv) {
    const ext = path.extname(argv.input);
    if (ext !== ".ts") {
      console.error(`invalid file extension ${ext}.`);
      return false;
    }

    try {
      fs.statSync(argv.input);
    } catch (err) {
      console.error(`File ${argv.input} not found.`);
      return false;
    }
    return true;
  })
  .help().argv;

const createAvs = (path, filename) => {
  fs.writeFileSync(
    path,
//    `LoadPlugin("/usr/local/lib/libffms2.so")
//FFIndex("${filename}")
//FFMpegSource2("${filename}", atrack=-1)`
`TSFilePath="${filename}"
LWLibavVideoSource(TSFilePath, repeat=true, dominance=1)
AudioDub(last,LWLibavAudioSource(TSFilePath))
`
  );
  return path;
};

const main = () => {
  const inputFile = argv.input;
  const inputFileName = path.basename(inputFile, path.extname(inputFile));
  const ffmpegOutputFile = argv.filter;
  const avsOutputFile = argv.avs;
  const settings = require("./settings").init(inputFileName);  //settings init
  const parseChannel = require("./channel").parse;
  const parseParam = require("./param").parse;
  const logoframe = require("./command/logoframe").exec;
  const chapterexe = require("./command/chapterexe").exec;
  const joinlogoframe = require("./command/join_logo_frame").exec;
  const createFilter = require("./output/ffmpeg_filter").create;
  const { INPUT_AVS, OUTPUT_AVS_CUT, OUTPUT_FILTER_CUT } = settings;
  const createOutAvs = require("./output/avs").create;
  const avsFile = createAvs(INPUT_AVS, inputFile);
  const channel = parseChannel(inputFile);
  const param = parseParam(channel, inputFileName);

  chapterexe(avsFile);
  logoframe(param, channel, avsFile);
  joinlogoframe(param);

  createFilter(inputFile, OUTPUT_AVS_CUT, OUTPUT_FILTER_CUT);
  createOutAvs(avsFile);
};

main();
