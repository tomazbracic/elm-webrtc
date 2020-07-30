// Generated by BUCKLESCRIPT, PLEASE EDIT WITH CARE

import * as Phoenix from "phoenix";

function sendWebRtcMessage(channel, content) {
  console.log(content);
  var content$1 = JSON.stringify(content);
  if (content$1 !== undefined) {
    channel.push("peer-message", {
          body: content$1
        }, undefined);
  } else {
    console.log("Ooooops, something went wrong :/");
  }
  
}

function createChannel(room, userId) {
  var socket = new Phoenix.Socket("/socket", {
        params: {
          user_id: userId
        }
      });
  socket.connect();
  var channel = new Phoenix.Channel("videoroom:" + room, {}, socket);
  channel.join(1000);
  return {
          socket: socket,
          channel: channel
        };
}

export {
  sendWebRtcMessage ,
  createChannel ,
  
}
/* phoenix Not a pure module */