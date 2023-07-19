#include<Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>

// Create an instance of CPositionInfo
CPositionInfo m_position;
// Create an instance of CTrade
CTrade trade;

void OnTick() {
  // Price Array for current price
  MqlRates PriceArray[];

  //array for MA
  double myMovingAverageArray1[];

  //Array for Momentum
  double myPriceArray[];
  double myPriceArray1[];

  // define the properties of the Moving Average1
  int movingAverageDefinition1 = iMA(_Symbol, PERIOD_H4, 50, 0, MODE_EMA, PRICE_CLOSE);

  // define the properties of the Momentum EA
  int iMomentumDefinition = iMomentum(_Symbol, _Period, 14, PRICE_CLOSE);

  // We calculate the Ask Price
  double Ask = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits);

  // We calculate the Bid Price
  double Bid = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits);

  //Current Account Equity
  double myAccountEquity = AccountInfoDouble(ACCOUNT_EQUITY);

  //Current Account Balance
  double myAccountBalance = AccountInfoDouble(ACCOUNT_BALANCE);

  double myAccountMargin = AccountInfoDouble(ACCOUNT_MARGIN_LEVEL);

  // Calculate the lot size
  double LotSize = NormalizeDouble(((0.025 * myAccountBalance) / 100), 2);

  //if (LotSize >= 0.3) {LotSize = 0.3;}

  // sort the price array1 MA
  ArraySetAsSeries(myMovingAverageArray1, true);

  // sort the price array1 (Momentum)
  ArraySetAsSeries(myPriceArray, true);

  // Sort the array ATR
  ArraySetAsSeries(PriceArray, true);

  // Defined MA data
  CopyBuffer(movingAverageDefinition1, 0, 0, 20, myMovingAverageArray1);

  // Defined Momentum data
  CopyBuffer(iMomentumDefinition, 0, 0, 96, myPriceArray);
  CopyBuffer(iMomentumDefinition, 0, 0, 12, myPriceArray1);

  // Get the value of the current candle momentum
  double myMomentumValue = NormalizeDouble(myPriceArray[0], 2);
  double myMomentumValue1 = NormalizeDouble(myPriceArray[1], 2);
  double myMomentumValue2 = NormalizeDouble(myPriceArray[2], 2);
  double myMomentumValue3 = NormalizeDouble(myPriceArray[3], 2);

  double MAValue = NormalizeDouble(myMovingAverageArray1[0], 5);

  // We fill the array with price data
  int Data = CopyRates(Symbol(), Period(), 0, 1, PriceArray);

  // Get current position opening price
  double currentPosPrice = PositionGetDouble(POSITION_PRICE_OPEN);

  //Average value of slow MA
  double SlowMAAverage = 0;
  
  int SlowMASize = ArraySize(myMovingAverageArray1);

  for (int i = 0; i < SlowMASize; i++) {
    SlowMAAverage += myMovingAverageArray1[i];
  }

  SlowMAAverage = NormalizeDouble(SlowMAAverage / 20, 6);

  ObjectCreate(0, "MAHLine", OBJ_HLINE, 0, 0, SlowMAAverage);
  ObjectSetInteger(0, "MAHLine", OBJPROP_COLOR, clrYellow);
  ObjectCreate(0, "MAHLineUpLimit", OBJ_HLINE, 0, 0, (SlowMAAverage + ((SlowMAAverage * 0.3) / 100)));
  ObjectCreate(0, "MAHLineDownLimit", OBJ_HLINE, 0, 0, (SlowMAAverage - ((SlowMAAverage * 0.3) / 100)));
  ObjectCreate(0, "MAHLineValue", OBJ_HLINE, 0, 0, MAValue);
  ObjectSetInteger(0, "MAHLineValue", OBJPROP_COLOR, clrAquamarine);

  // Up trend and down trend conditions
  bool ConditionUpTrend = false;

  if (MAValue > SlowMAAverage) {
    ConditionUpTrend = true;
  }

  //Averages of Momentum
  double MomentumAverage = 0;
  double MomentumTopLimit = 0;
  double MomentumBotLimit = 0;
  double MomentumFastAverage = 0;

  int MomentumArrSize = ArraySize(myPriceArray);

  for (int i = 0; i < MomentumArrSize; i++) {
    MomentumAverage += myPriceArray[i];
  }

  MomentumAverage = NormalizeDouble(MomentumAverage / 96, 2);

  MomentumTopLimit = NormalizeDouble(MomentumTopLimit, 2);
  MomentumBotLimit = NormalizeDouble(MomentumBotLimit, 2);

  int MomentumArrSize1 = ArraySize(myPriceArray1);

  for (int i = 0; i < MomentumArrSize1; i++) {
    MomentumFastAverage += myPriceArray1[i];
  }

  MomentumFastAverage = NormalizeDouble(MomentumFastAverage / 12, 2);

  if (ConditionUpTrend == true) {
    MomentumTopLimit = (MomentumAverage + (MomentumFastAverage * 0.0037));
    MomentumBotLimit = (MomentumAverage - (MomentumFastAverage * 0.0039));
  }

  if (ConditionUpTrend == false) {
    MomentumTopLimit = (MomentumAverage + (MomentumFastAverage * 0.0039));
    MomentumBotLimit = (MomentumAverage - (MomentumFastAverage * 0.0037));
  }

  ObjectCreate(0, "MomAVRGHline", OBJ_HLINE, ChartWindowFind(0, "Momentum(14)"), 0, MomentumAverage);
  ObjectCreate(0, "MomAVRGHlineTop", OBJ_HLINE, ChartWindowFind(0, "Momentum(14)"), 0, MomentumTopLimit);
  ObjectCreate(0, "MomAVRGHlineBot", OBJ_HLINE, ChartWindowFind(0, "Momentum(14)"), 0, MomentumBotLimit);
  ObjectCreate(0, "MomAVRGHFline", OBJ_HLINE, ChartWindowFind(0, "Momentum(14)"), 0, MomentumFastAverage);

  ObjectSetInteger(0, "MomAVRGHlineTop", OBJPROP_COLOR, clrYellow);
  ObjectSetInteger(0, "MomAVRGHlineBot", OBJPROP_COLOR, clrYellow);
  ObjectSetInteger(0, "MomAVRGHFline", OBJPROP_COLOR, clrCyan);

  if (ConditionUpTrend == true) {
    ObjectCreate(0, "TakeProfitSellUptrend", OBJ_HLINE, ChartWindowFind(0, "Momentum(14)"), 0, ((MomentumAverage + MomentumBotLimit) / 2));
    ObjectSetInteger(0, "TakeProfitSellUptrend", OBJPROP_COLOR, clrLime);
    ObjectDelete(0, "TakeProfitBuyDowntrend");
  }

  if (ConditionUpTrend == false) {
    ObjectCreate(0, "TakeProfitBuyDowntrend", OBJ_HLINE, ChartWindowFind(0, "Momentum(14)"), 0, ((MomentumAverage + MomentumTopLimit) / 2));
    ObjectSetInteger(0, "TakeProfitBuyDowntrend", OBJPROP_COLOR, clrLime);
    ObjectDelete(0, "TakeProfitSellUptrend");
  }

  // Stop Loss
  double StopLoss = SlowMAAverage;

  // Take Profit
  double TakeProfitBuy = (currentPosPrice + ((currentPosPrice * 0.05) / 100));

  double TakeProfitSell = (currentPosPrice - ((currentPosPrice * 0.05) / 100));

  double StopLossBuy = (currentPosPrice - ((currentPosPrice * 0.5) / 100));
  double StopLossSell = (currentPosPrice + ((currentPosPrice * 0.5) / 100));

  // Position Management
  int count_positions = 0;

  for (int i = PositionsTotal() - 1; i >= 0; i--) {
  
    if (m_position.SelectByIndex(i)) {
      if (m_position.Symbol() == PositionGetString(POSITION_SYMBOL)) {
        if (m_position.PositionType() == POSITION_TYPE_BUY) {
          ulong positionTicket1 = PositionGetTicket(i);
          count_positions++; {
            if (myMomentumValue >= MomentumTopLimit) {
              trade.PositionClose(positionTicket1, 0);
            } else if ((ConditionUpTrend == false) &&
              (myMomentumValue >= ((MomentumAverage + MomentumTopLimit) / 2))) {
              trade.PositionClose(positionTicket1, 0);

            } else {
              if (myAccountMargin <= 55)
                trade.PositionClose(positionTicket1, 0);
            }
          }
        }

        if (m_position.PositionType() == POSITION_TYPE_SELL) {
          ulong positionTicket2 = PositionGetTicket(i);
          count_positions++; {
            if (myMomentumValue <= MomentumBotLimit) {
              trade.PositionClose(positionTicket2, 0);

            } else if ((ConditionUpTrend == true) &&
              (myMomentumValue <= ((MomentumAverage + MomentumBotLimit) / 2))) {
              trade.PositionClose(positionTicket2, 0);

            } else {
              if (myAccountMargin <= 55)
                trade.PositionClose(positionTicket2, 0);

            }
          }
        }
      }
    }
  }

  // Conditions for position opening

  if (count_positions == 0) {
    if (myMomentumValue <= MomentumBotLimit && myMomentumValue > MomentumFastAverage) {
      if ((Ask > (SlowMAAverage + ((SlowMAAverage * 0.3) / 100))) ||
        (Bid < (SlowMAAverage - ((SlowMAAverage * 0.3) / 100)))) {
        if (ConditionUpTrend == true) {
          trade.Buy(LotSize, NULL, Ask, 0, 0);
        } else if (ConditionUpTrend == false && count_positions == 0) {
          trade.Buy(NormalizeDouble((LotSize / 2), 2), NULL, Ask, 0, 0);
        }
      }
    }
  }

  if (count_positions == 0) {
    if (myMomentumValue >= MomentumTopLimit && myMomentumValue < MomentumFastAverage) {
      if ((Ask > (SlowMAAverage + ((SlowMAAverage * 0.3) / 100))) ||
        (Bid < (SlowMAAverage - ((SlowMAAverage * 0.3) / 100)))) {
        if (ConditionUpTrend == false) {
          trade.Sell(LotSize, NULL, Bid, 0, 0);
        } else if (ConditionUpTrend == true && count_positions == 0) {
          trade.Sell(NormalizeDouble((LotSize / 2), 2), NULL, Bid, 0, 0);
        }
      }

    }
  }

}