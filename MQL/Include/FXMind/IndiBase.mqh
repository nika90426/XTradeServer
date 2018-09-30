//+------------------------------------------------------------------+
//|                                                 ThriftClient.mqh |
//|                                                 Sergei Zhuravlev |
//|                                   http://github.com/sergiovision |
//+------------------------------------------------------------------+
#property copyright "Sergei Zhuravlev"
#property link      "http://github.com/sergiovision"
#property strict

#include <Indicators\Indicator.mqh>
#include <FXMind\IUtils.mqh>

class TradeSignals;

class IndiBase :  public CIndicator
{
protected:
   bool m_bInited;
   TradeSignals*      signals;


public:
   IndiBase (TradeSignals* s)
   {
      m_bInited = false;
      signals = s;

   }
   virtual bool Init(ENUM_TIMEFRAMES timeframe) = 0;
   virtual bool Process(Signal& signal) = 0;
   virtual void Trail(Order &order, int indent) {}
   virtual void Delete() = 0;
   virtual bool Initialized() { return m_bInited; }
   virtual bool      Initialize(const string symbol,const ENUM_TIMEFRAMES period,
                                const int num_params,const MqlParam &params[]) 
   {
      return(true);
   }
   bool TrailLevel(Order& order, double ask, double bid, double SL, double TP, double level);
   
   #ifdef __MQL5__
   virtual int GetIndicatorData(int BuffIndex, int startPos, int Count, double &Buffer[])
   {
        return CopyBuffer(Handle(), BuffIndex, startPos, Count, Buffer);;
   }
#else
   virtual int GetIndicatorData(int BuffIndex, int startPos, int Count, double &Buffer[])
   {
        ArrayResize(Buffer, Count);
        for (int i = 0; i < Count;i++)
        {
            Buffer[i] = GetData(BuffIndex, i);
        }
        return Count;
   }
#endif 


   virtual int       Handle() const 
   {
#ifdef  __MQL5__
      return(m_handle);   
#else
      return(0);   
#endif      
   }
};

bool IndiBase::TrailLevel(Order& order, double ask, double bid, double SL, double TP, double level)
{
    if ( bid > level ) 
    {
        if ( (order.type == OP_BUY) && ((level - signals.trailDelta) < (bid - signals.trailDelta)))
        {
           SL = level - signals.trailDelta;

           if (!signals.methods.ChangeOrder(order, SL, TP, order.expiration, signals.methods.TrailingColor))
              {
              }//if (Utils.IsTesting())
               //Print("Invalid Stop " + order.ToString());
           return true;
        }
    }
    
    if ( ask < level ) 
    {
        if ((order.type == OP_SELL) && ((level + signals.trailDelta) > (ask + signals.trailDelta)) )
        {
           SL = level + signals.trailDelta;
           if (!signals.methods.ChangeOrder(order, SL, TP, order.expiration, signals.methods.TrailingColor))
               {
               }//if (Utils.IsTesting())
               //Print("Invalid Stop " + order.ToString());
           return true;
        }
    }
    return false;
}
