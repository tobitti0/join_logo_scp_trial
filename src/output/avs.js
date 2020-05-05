const fs = require("fs");
async = require("async");

const createfile = (inputfiles, outputfile) =>{
  const writer = fs.createWriteStream(outputfile, {encoding: 'utf-8'});
  async.mapSeries(inputfiles, (fn, callback) => {
    const reader = fs.createReadStream(fn, {encoding: 'utf-8'});
    reader.on("end", () => {
      reader.unpipe();
      callback();
    });
    reader.pipe(writer, { end: false });
  }, () => {
    // finally, close the WritableStream
    writer.end();
  });
};

exports.create = inputFile => {
  try {
    const { OUTPUT_AVS_CUT, 
            LOGOFRAME_AVS_OUTPUT, 
            OUTPUT_AVS_IN_CUT,
            OUTPUT_AVS_IN_CUT_LOGO 
          } = require("../settings");
    createfile([inputFile, OUTPUT_AVS_CUT], OUTPUT_AVS_IN_CUT);
    createfile([inputFile, LOGOFRAME_AVS_OUTPUT, OUTPUT_AVS_CUT], OUTPUT_AVS_IN_CUT_LOGO);
    
  } catch (e) {
    console.error(e);
    process.exit(-1);
  }
};

