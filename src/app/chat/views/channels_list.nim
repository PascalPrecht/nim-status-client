import NimQml
import Tables

import ../../../models/chat

type
  ChannelsRoles {.pure.} = enum
    Name = UserRole + 1,
    LastMessage = UserRole + 2
    Timestamp = UserRole + 3
    UnreadMessages = UserRole + 4

QtObject:
  type
    ChannelsList* = ref object of QAbstractListModel
      model*: ChatModel
      chats*: seq[ChatItem]

  proc setup(self: ChannelsList) = self.QAbstractListModel.setup

  proc delete(self: ChannelsList) = self.QAbstractListModel.delete

  proc newChannelsList*(model: ChatModel): ChannelsList =
    new(result, delete)
    result.model = model
    result.setup()

  method rowCount(self: ChannelsList, index: QModelIndex = nil): int = self.chats.len

  method data(self: ChannelsList, index: QModelIndex, role: int): QVariant =
    if not index.isValid:
      return
    if index.row < 0 or index.row >= self.chats.len:
      return

    let chatItem = self.chats[index.row]
    let chatItemRole = role.ChannelsRoles
    case chatItemRole:
      of ChannelsRoles.Name: result = newQVariant(chatItem.name)
      of ChannelsRoles.Timestamp: result = newQVariant($chatItem.timestamp)
      of ChannelsRoles.LastMessage: result = newQVariant(chatItem.lastMessage)
      of ChannelsRoles.UnreadMessages: result = newQVariant(chatItem.unviewedMessagesCount)

  method roleNames(self: ChannelsList): Table[int, string] =
    { 
      ChannelsRoles.Name.int:"name",
      ChannelsRoles.Timestamp.int:"timestamp",
      ChannelsRoles.LastMessage.int: "lastMessage",
      ChannelsRoles.UnreadMessages.int: "unviewedMessagesCount"
    }.toTable

  proc addChatItemToList*(self: ChannelsList, channel: ChatItem): int =
    # self.upsertChannel(channel.name)
    self.beginInsertRows(newQModelIndex(), self.chats.len, self.chats.len)
    self.chats.add(channel)
    self.endInsertRows()
    
    result = self.chats.len - 1

  proc joinChat*(self: ChannelsList, channel: string): int {.slot.} =
    # self.setActiveChannel(channel)
    if self.model.hasChannel(channel):
      result = self.chats.findByName(channel)
    else:
      self.model.join(channel)
      result = self.addChatItemToList(ChatItem(name: channel))

  proc updateChat*(self: ChannelsList, chat: ChatItem) =
    var idx = self.chats.findByName(chat.name)
    if idx > -1:
      self.chats[idx] = chat
      var x = self.createIndex(idx,0,nil)
      var y = self.createIndex(idx,0,nil)
      self.dataChanged(x, y, @[ChannelsRoles.Timestamp.int, ChannelsRoles.LastMessage.int, ChannelsRoles.UnreadMessages.int])
