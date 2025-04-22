-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	WindowTabManager.registerTab("partysheet_host", { sName = "domain", sTabRes = "tab_domain", sClass = "ps_domain" });
	WindowTabManager.registerTab("partysheet_host", { sName = "powerpool", sTabRes = "tab_powerpool", sClass = "ps_powerpool" });
	
	WindowTabManager.registerTab("partysheet_client", { sName = "domain", sTabRes = "tab_domain", sClass = "ps_domain" });
	WindowTabManager.registerTab("partysheet_client", { sName = "powerpool", sTabRes = "tab_powerpool", sClass = "ps_powerpool" });
end