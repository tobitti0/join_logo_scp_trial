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
    type: "boolean",
    default: false,
    describe: "enable to ffmpeg filter output"
  })
  .option("encode", {
    alias: "e",
    type: "boolean",
    default: false,
    describe: "enable to ffmpeg encode"
  })
  .option("target", {
    alias: "t",
    choices: ["cutcm", "cutcm_logo"],
    default: "cutcm_logo",
    describe: "select encord target"
  })
  .option("option", {
    alias: "o",
    type: "string",
    default: "",
    describe: "set ffmpeg option"
  })
  .option("name", {
    alias: "n",
    type: "string",
    default: "",
    describe: "set encordet file name"
  })
  .option("remove", {
    alias: "r",
    type: "boolean",
    default: false,
    describe: "remove avs files"
  })
  .demandOption(
    ["input"],
    "Please provide input arguments to work with this tool"
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
//`LoadPlugin("/usr/local/lib/libffms2.so")
//FFIndex("${filename}")
//FFMpegSource2("${filename}", atrack=-1)`
`TSFilePath="${filename}"
LWLibavVideoSource(TSFilePath, repeat=true, dominance=1)
AudioDub(last,LWLibavAudioSource(TSFilePath, stream_index=1, av_sync=true))
`
  );
  return path;
};

const main = async () => {
  const inputFile =  path.resolve(argv.input);
  const inputFileName = path.basename(inputFile, path.extname(inputFile));
  const inputFileDir = path.dirname(inputFile);
  const settings = require("./settings").init(inputFileName);  //settings init
  const parseChannel = require("./channel").parse;
  const parseParam = require("./param").parse;
  const logoframe = require("./command/logoframe").exec;
  const chapterexe = require("./command/chapterexe").exec;
  const joinlogoframe = require("./command/join_logo_frame").exec;
  const createFilter = require("./output/ffmpeg_filter").create;
  const createOutAvs = require("./output/avs").create;
  const encode = require("./command/ffmpeg").exec;
  const { INPUT_AVS, 
          OUTPUT_AVS_CUT, 
          OUTPUT_FILTER_CUT, 
          SAVE_DIR
        } = settings;
  const avsFile = createAvs(INPUT_AVS, inputFile);
  const channel = parseChannel(inputFile);
  const param = parseParam(channel, inputFileName);

  chapterexe(avsFile);
  logoframe(param, channel, avsFile);
  joinlogoframe(param);

  await createOutAvs(avsFile);

  if(argv.filter) {createFilter(inputFile, OUTPUT_AVS_CUT, OUTPUT_FILTER_CUT); }

  if(argv.encode) {
    encode(inputFileDir, argv.name? argv.name : inputFileName, argv.target, argv.option);
  }
  if(argv.remove) {
    fs.removeSync(SAVE_DIR);
    fs.removeSync(path.join(inputFileDir,`${inputFileName}.ts.lwi`));
  }
};

main();
