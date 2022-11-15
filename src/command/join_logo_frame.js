const childProcess = require('child_process');
const path = require("path");
const fs = require("fs-extra");

const {
  JL_DIR,
  JLSCP_COMMAND,
  LOGOFRAME_TXT_OUTPUT,
  CHAPTEREXE_OUTPUT,
  JLSCP_OUTPUT,
  OUTPUT_AVS_CUT
} = require("../settings");

exports.exec = param => {
  return new Promise((resolve)=>{
    let args = [];
    if( fs.existsSync( LOGOFRAME_TXT_OUTPUT ) ){
      args.push( "-inlogo", LOGOFRAME_TXT_OUTPUT );
    }
    args.push(
      "-inscp",
      CHAPTEREXE_OUTPUT,
      "-incmd",
      path.join(JL_DIR, param.JLOGO_CMD),
      "-o",
      OUTPUT_AVS_CUT,
      "-oscp",
      JLSCP_OUTPUT,
      "-flags",
      param.JL_FLAGS
    );

    if (param.JLOGO_OPT1 && param.JLOGO_OPT1 !== "") {
      args = args.concat(param.JLOGO_OPT1.split(" "));
    }

    if (param.JLOGO_OPT2 && param.JLOGO_OPT2 !== "") {
      args = args.concat(param.JLOGO_OPT2.split(" "));
    }

    console.log(args)
    const child = childProcess.spawn(JLSCP_COMMAND, args);
    child.on('exit', (code)=>{
      resolve();
    });
    child.stderr.on('data', (data)=>{
      console.error("join_logo_frame " + String(data).replace(/\n$/,""));
    });
  })
};
