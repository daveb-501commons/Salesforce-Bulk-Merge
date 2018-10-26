/*
    Copyright (c) 2016, Salesforce.org
    All rights reserved.
    
    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:
    
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of Salesforce.org nor the names of
      its contributors may be used to endorse or promote products derived
      from this software without specific prior written permission.
 
    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
    "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT 
    LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS 
    FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE 
    COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, 
    INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, 
    BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; 
    LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER 
    CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT 
    LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN 
    ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
    POSSIBILITY OF SUCH DAMAGE.
*/

@isTest
private with sharing class C501_CTRL_MassMergeAccounts_TEST {
    
    //==================== TEST METHOD(s) ======================================
    private static testmethod void CodeCoverageTests() {
    
        // set up intial test data
        Account acc = new Account(name='Individual Test User');
        insert acc;

        list<Account> listAccounts = new list<Account>();   
        integer cAccounts = 5;     
        for (integer i = 0; i < cAccounts; i++) {
            Account account = new Account(
                
                // Request Information
                Name='Account Name'
            );
            listAccounts.add(account);
        }                       
        insert listAccounts;
        
        //point to our VF page
        PageReference p = new PageReference('Page.MassMergeAccounts');
        p.getParameters().put('Id', acc.id);
        Test.setCurrentPageReference(p);
        
        //instantiate the controller for this opp
        C501_CTRL_MassMergeAccounts ctrl = new C501_CTRL_MassMergeAccounts();
        System.AssertEquals(acc.Id, ctrl.accountFilter.Id);
        System.Assert(ctrl.listSOAccounts.size() > 1);
        System.AssertEquals(cAccounts, ctrl.listAccounts.size());
        
        ctrl.accountFilter.Id = null;
        ctrl.ChangeProgram();
        System.AssertEquals(null, ctrl.listAccounts);
        
        ctrl.accountFilter.Id = acc.Id;
        ctrl.ChangeProgram();
        ctrl.ChangeProgram();
        System.AssertEquals(cAccounts, ctrl.listAccounts.size());
        System.AssertEquals(0, ctrl.numberOfRecordsDirty);
        
        //ctrl.listAccounts.get(0).Amount = 2;
        p.getParameters().put('usersIdDirtied', ctrl.listAccounts.get(0).id);
        ctrl.AccountsRecordModified();
        System.AssertEquals(1, ctrl.setAccountsIdDirty.size());
        
        Account account = ctrl.listAccounts.get(ctrl.listAccounts.size() - 1);
        p.getParameters().put('usersIdDirtied', null);
        ctrl.AccountsRecordModified();
        System.AssertEquals(1, ctrl.setAccountsIdDirty.size());
        System.AssertEquals(1, ctrl.numberOfRecordsDirty);

        // test the save!
        ctrl.SaveAccounts();
        system.debug(ctrl.strSaveResults);
        System.Assert(ctrl.strSaveResults.startsWith('Error'));
        ctrl.ChangeProgram();
        ctrl.SaveAndCloseAccounts();      
        System.AssertEquals(0, ctrl.numberOfRecordsDirty);
        
    }

    private static testMethod void testPageMessagesController() {
        ApexPages.addMessage(new ApexPages.message(ApexPages.severity.WARNING,'summary'));
        C501_UTIL_PageMessages_CTRL controller = new C501_UTIL_PageMessages_CTRL();
        List<C501_UTIL_PageMessages_CTRL.Message> messages = controller.getPageMessages();

        System.assertEquals(1, messages.size(), 'There should be one error on the page.');
        System.assertEquals(Label.PageMessagesWarning, messages[0].getSeverityLabel(), 'The label should be WARNING.');
        System.assertEquals('warning', messages[0].getSeverityTheme(), 'The theme should be warning.');
    }
}