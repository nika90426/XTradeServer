﻿using System;
using DevExpress.Xpo;
using DevExpress.Data.Filtering;
using System.Collections.Generic;
using System.ComponentModel;
namespace Solution1.Module.BusinessObjects.fx_mind
{

    public partial class DBWallet
    {
        public DBWallet(Session session) : base(session) { }
        public override void AfterConstruction() { base.AfterConstruction(); }
    }

}
