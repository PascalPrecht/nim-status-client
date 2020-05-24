import NimQml
import eventemitter
import strformat
import json
import "../../status/core" as status
import ../../status/mailservers as status_mailservers
import ../../signals/types
import view
import "../../status/types" as status_types
import ../../models/profile

type ProfileController* = ref object of SignalSubscriber
  view*: ProfileView
  variant*: QVariant
  appEvents*: EventEmitter

proc newController*(appEvents: EventEmitter): ProfileController =
  result = ProfileController()
  result.appEvents = appEvents
  result.view = newProfileView()
  result.variant = newQVariant(result.view)

proc delete*(self: ProfileController) =
  delete self.view
  delete self.variant

proc init*(self: ProfileController, account: Account) =
  let profile = account.toProfileModel()
  self.view.setNewProfile(profile)

  var mailservers = status_mailservers.getMailservers()
  for mailserver_config in mailservers:
    let mailserver = MailServer(name: mailserver_config[0], endpoint: mailserver_config[1])
    self.view.addMailServerToList(mailserver)

  self.view.addContactToList(Contact(name: "username1", address: "0x12345"))
  self.view.addContactToList(Contact(name: "username2", address: "0x23456"))
  self.view.addContactToList(Contact(name: "username3", address: "0x34567"))
