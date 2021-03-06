//+------------------------------------------------------------------+
//|                                           CommandsController.mqh |
//|                                                 Sergei Zhuravlev |
//|                                   http://github.com/sergiovision |
//+------------------------------------------------------------------+
#property copyright "Sergei Zhuravlev"
#property link      "http://github.com/sergiovision"
#property strict

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
interface CommandsController 
{
   bool CheckActive();
   void HandleSignal(int id, long lparam, double dparam, string signalStr);
   void ReturnActiveOrders();
};

