{-# LANGUAGE DeriveDataTypeable         #-}
{-# LANGUAGE DeriveGeneric              #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE OverloadedStrings          #-}
{-# LANGUAGE RecordWildCards            #-}


module Coinbase.Exchange.Types.Socket where

import           Control.DeepSeq
import           Control.Monad
import           Data.Aeson.Types      hiding (Error)
import           Data.Data
import           Data.Hashable
import           Data.Text                    (Text)
import           Data.Time
import           Data.Word
import           GHC.Generics

import           Coinbase.Exchange.Types.Core  hiding (OrderStatus(..))

data ExchangeMessage
    = Subscribe
        { msgProductId :: ProductId
        }
    | ReceivedLimit
        { msgTime      :: UTCTime
        , msgProductId :: ProductId
        , msgSequence  :: Sequence
        , msgOrderId   :: OrderId
        , msgSide      :: Side
        , msgClientOid :: Maybe ClientOrderId
        --
        , msgPrice     :: Price
        , msgSize      :: Size
        }
    | ReceivedMarket
        { msgTime      :: UTCTime
        , msgProductId :: ProductId
        , msgSequence  :: Sequence
        , msgOrderId   :: OrderId
        , msgSide      :: Side
        , msgClientOid :: Maybe ClientOrderId
        -- market orders have no price and are bounded by either size, funds or both
        , msgMarketBounds :: (Either Size (Maybe Size, Cost))
        }
    | Open
        { msgTime          :: UTCTime
        , msgProductId     :: ProductId
        , msgSequence      :: Sequence
        , msgOrderId       :: OrderId
        , msgSide          :: Side
        , msgRemainingSize :: Size
        , msgPrice         :: Price
        }
    | Done
        { msgTime      :: UTCTime
        , msgProductId :: ProductId
        , msgSequence  :: Sequence
        , msgOrderId   :: OrderId
        , msgSide      :: Side
        , msgRemainingSize :: Size
        , msgPrice     :: Price
        , msgReason    :: Reason
        , msgOrderType :: OrderType
        }
    | Match
        { msgTime         :: UTCTime
        , msgProductId    :: ProductId
        , msgSequence     :: Sequence
        , msgSide         :: Side
        , msgTradeId      :: TradeId
        , msgMakerOrderId :: OrderId
        , msgTakerOrderId :: OrderId
        , msgSize         :: Size
        , msgPrice        :: Price
        }
    | ChangeLimit
        { msgTime      :: UTCTime
        , msgProductId :: ProductId
        , msgSequence  :: Sequence
        , msgOrderId   :: OrderId
        , msgSide      :: Side
        , msgPrice     :: Price
        , msgNewSize   :: Size
        , msgOldSize   :: Size
        }
    | ChangeMarket
        { msgTime      :: UTCTime
        , msgProductId :: ProductId
        , msgSequence  :: Sequence
        , msgOrderId   :: OrderId
        , msgSide      :: Side
        , msgPrice     :: Price
        , msgNewFunds  :: Cost
        , msgOldFunds  :: Cost
        }
    | Error
        { msgMessage :: Text
        }
    deriving (Eq, Show, Read, Data, Typeable, Generic)

instance NFData ExchangeMessage

-----------------------------
instance FromJSON ExchangeMessage where
    parseJSON = genericParseJSON coinbaseAesonOptions

-- instance FromJSON ExchangeMessage where
--     parseJSON (Object m) = do
--         msgtype <- m .: "type"
--         case (msgtype :: String) of
--             "open" -> Open
--                 <$> m .: "time"
--                 <*> m .: "product_id"
--                 <*> m .: "sequence"
--                 <*> m .: "order_id"
--                 <*> m .: "side"
--                 <*> m .: "remaining_size"
--                 <*> m .: "price"
--             "done" -> Done
--                 <$> m .: "time"
--                 <*> m .: "product_id"
--                 <*> m .: "sequence"
--                 <*> m .: "order_id"
--                 <*> m .: "side"
--                 <*> m .: "remaining_size"
--                 <*> m .: "price"
--                 <*> m .: "reason"
--                 <*> m .: "order_type"
--             "match" -> Match
--                 <$> m .: "time"
--                 <*> m .: "product_id"
--                 <*> m .: "sequence"
--                 <*> m .: "side"
--                 <*> m .: "trade_id"
--                 <*> m .: "maker_order_id"
--                 <*> m .: "taker_order_id"
--                 <*> m .: "size"
--                 <*> m .: "price"
--             "change" -> do
--                 ms <- m .:? "new_size"
--                 case (ms :: Maybe Size) of
--                     Nothing -> ChangeMarket
--                                 <$> m .: "time"
--                                 <*> m .: "product_id"
--                                 <*> m .: "sequence"
--                                 <*> m .: "order_id"
--                                 <*> m .: "side"
--                                 <*> m .: "price"
--                                 <*> m .: "new_funds"
--                                 <*> m .: "old_funds"
--                     Just _ -> ChangeLimit
--                                 <$> m .: "time"
--                                 <*> m .: "product_id"
--                                 <*> m .: "sequence"
--                                 <*> m .: "order_id"
--                                 <*> m .: "side"
--                                 <*> m .: "price"
--                                 <*> m .: "new_size"
--                                 <*> m .: "old_size"
--             "received" -> do
--                 typ  <- m .:  "order_type"
--                 mcid <- m .:? "client_id"
--                 case typ of
--                     Limit -> ReceivedLimit
--                                 <$> m .: "time"
--                                 <*> m .: "product_id"
--                                 <*> m .: "sequence"
--                                 <*> m .: "order_id"
--                                 <*> m .: "side"
--                                 <*> pure (mcid :: Maybe ClientOrderId)
--                                 <*> m .: "price"
--                                 <*> m .: "size"
--                     Market -> ReceivedMarket
--                                 <$> m .: "time"
--                                 <*> m .: "product_id"
--                                 <*> m .: "sequence"
--                                 <*> m .: "order_id"
--                                 <*> m .: "side"
--                                 <*> pure mcid
--                                 <*> (do
--                                         ms <- m .:? "size"
--                                         mf <- m .:? "funds"
--                                         case (ms,mf) of
--                                             (Nothing, Nothing) -> mzero
--                                             (Just s , Nothing) -> return $ Left  s
--                                             (Nothing, Just f ) -> return $ Right (Nothing, f)
--                                             (Just s , Just f ) -> return $ Right (Just s , f)
--                                             )
--
--     parseJSON _ = mzero
-----------------------------


instance ToJSON ExchangeMessage where
    toJSON Subscribe{..} = object ["product_id" .= msgProductId]
    toJSON Open{..} = object
        [ "type"       .= ("open" :: Text)
        , "time"       .= msgTime
        , "product_id" .= msgProductId
        , "sequence"   .= msgSequence
        , "order_id"   .= msgOrderId
        , "side"       .= msgSide
        , "remaining_size" .= msgRemainingSize
        , "price"      .= msgPrice
        ]
    toJSON Done{..} = object
        [ "type"       .= ("done" :: Text)
        , "time"       .= msgTime
        , "product_id" .= msgProductId
        , "sequence"   .= msgSequence
        , "order_id"   .= msgOrderId
        , "side"       .= msgSide
        , "remaining_size" .= msgRemainingSize
        , "price"      .= msgPrice
        , "reason"     .= msgReason
        , "order_type" .= msgOrderType
        ]
    toJSON Match{..} = object
        [ "type"       .= ("match" :: Text)
        , "time"       .= msgTime
        , "product_id" .= msgProductId
        , "sequence"   .= msgSequence
        , "side"       .= msgSide
        , "trade_id"   .= msgTradeId
        , "maker_order_id" .= msgMakerOrderId
        , "taker_order_id" .= msgTakerOrderId
        , "size"       .= msgSize
        , "price"      .= msgPrice
        ]
    toJSON Error{..} = object
        [ "type" .= ("error" :: Text)
        , "message" .= msgMessage
        ]
    toJSON ChangeLimit{..} = object
        [ "type"       .= ("change" :: Text)
        , "time"       .= msgTime
        , "product_id" .= msgProductId
        , "sequence"   .= msgSequence
        , "order_id"   .= msgOrderId
        , "side"       .= msgSide
        , "new_size"   .= msgNewSize
        , "old_size"   .= msgOldSize
        , "price"      .= msgPrice
        ]
    toJSON ChangeMarket{..} = object
        [ "type"       .= ("change" :: Text)
        , "time"       .= msgTime
        , "product_id" .= msgProductId
        , "sequence"   .= msgSequence
        , "order_id"   .= msgOrderId
        , "side"       .= msgSide
        , "price"      .= msgPrice
        , "new_funds"  .= msgNewFunds
        , "old_funds"  .= msgOldFunds
        ]

    toJSON ReceivedLimit{..} = object (
        [ "type"       .= ("received" :: Text)
        , "time"       .= msgTime
        , "product_id" .= msgProductId
        , "sequence"   .= msgSequence
        , "order_id"   .= msgOrderId
        , "side"       .= msgSide
        , "size"       .= msgSize
        , "price"      .= msgPrice
        , "order_type" .= Limit
        ] ++ clientID)
            where
                clientID = case msgClientOid of
                    Nothing -> []
                    Just ci -> ["client_id" .= msgClientOid ]

    toJSON ReceivedMarket{..} = object (
        ["type"       .= ("received" :: Text)
        , "time"       .= msgTime
        , "product_id" .= msgProductId
        , "sequence"   .= msgSequence
        , "order_id"   .= msgOrderId
        , "side"       .= msgSide
        , "order_type" .= Market
        ] ++ clientID ++ size ++ funds)
            where
                clientID = case msgClientOid of
                    Nothing -> []
                    Just ci -> ["client_id" .= msgClientOid ]
                (size,funds) = case msgMarketBounds of
                    Left  s -> (["size" .= s],[])
                    Right (ms,f) -> case ms of
                                Nothing -> ( []            , ["funds" .= f] )
                                Just s' -> ( ["size" .= s'], ["funds" .= f] )
