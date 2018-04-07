using log4net;
using System;
using System.Collections.Generic;
using Thrift.Protocol;

namespace BusinessObjects
{

    public class AppServiceClient : ThriftClient<AppService.Client>
    {
        private static readonly ILog log = LogManager.GetLogger(typeof(AppServiceClient));
        public AppServiceClient(string host, short port)
        { 
            try
            {
                Host = host;
                Port = port;
                InitBase();
            } catch (Exception e)
            {
                log.Error("AppServiceClient:" + e.ToString());
            }
        }

        public override AppService.Client CreateClient(TProtocol p)
        {
            client = new AppService.Client(p);
            return client;
        }

    }
}