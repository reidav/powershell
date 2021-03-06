﻿using System;
using System.Collections;
using System.IO;
using System.Linq;
using System.Management.Automation;
using System.Management.Automation.Runspaces;
using Microsoft.PowerShell.Commands;
using Microsoft.SharePoint.Client;

using File = System.IO.File;

namespace PnP.PowerShell.Commands.Provider.SPOProxy
{
    [Cmdlet(CmdletVerb, CmdletNoun, DefaultParameterSetName = "Path", SupportsShouldProcess = true, SupportsTransactions = true)]
    
    public class SPOProxyCopyItem : SPOProxyCmdletBase
    {
        public const string CmdletVerb = "Copy";

        internal override string CmdletType => CmdletVerb;

        [Parameter]
        public override SwitchParameter Recurse { get; set; }

        protected override void ProcessRecord()
        {
            SPOProxyImplementation.CopyMoveImplementation(this);
        }
    }
}
