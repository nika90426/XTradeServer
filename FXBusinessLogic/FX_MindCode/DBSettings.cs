﻿using System;
using DevExpress.Xpo;
using DevExpress.Data.Filtering;
using System.Collections.Generic;
using System.ComponentModel;
namespace FXBusinessLogic.fx_mind
{

    public partial class DBSettings
    {
        public DBSettings(Session session) : base(session) { }
        public override void AfterConstruction() { base.AfterConstruction(); }
    }

}
