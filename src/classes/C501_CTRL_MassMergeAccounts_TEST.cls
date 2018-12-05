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
    
    @testSetup static void setup() {

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

        C501_Merge_Metric__c mergeMetric = new C501_Merge_Metric__c(
            Name = 'MergeMetric',
            Enable__c = true
        );

        insert mergeMetric;

        List<C501_Service_Household__c> listServiceHouseholds = new List<C501_Service_Household__c>();
        List<C501_Account_Merge__c> listAccountMerges = new List<C501_Account_Merge__c>();
        List<Contact> listContacts = new List<Contact>();
        List<C501_Service_Contact__c> listServiceContacts = new List<C501_Service_Contact__c>();
        for (Account account :listAccounts) {
            listServiceHouseholds.add( new C501_Service_Household__c(
                Name = 'Name ' + account.Id,
                C501_Service_Id__c = 'C501_Service_Id__c ' + account.Id,
                C501_Household__c = account.Id,
                C501_Program__c = 'Energy Assistance',
                C501_Start_Date__c = date.today()
            ));

            listAccountMerges.add( new C501_Account_Merge__c(
                Unique_Id__c = 'Merge ' + account.Id,
                Merge_Metric__c = mergeMetric.Id,
                Account__c = listAccounts[0].Id,
                Merge_Target_Account__c = account.Id,
                Merge_Confidence__c = 100,
                Merge_Action__c = 'Merge'
            ));

            listContacts.add( new Contact(
                LastName = 'Test',
                FirstName = 'Test',
                C501_FirstName_Initial__c = 'T',
                AccountId = account.Id,
                Birthdate = date.today()
            ));
        }

        insert listServiceHouseholds;
        insert listAccountMerges;
        insert listContacts;

        Integer serviceHouseholdIndex = 0;
        for (Contact contact :listContacts) {
            listServiceContacts.add( new C501_Service_Contact__c(
                C501_Last_Name__c = 'Test',
                C501_First_Name__c = 'Test',
                C501_FirstName_Initial__c = 'T',
                C501_Birthdate__c = date.today(),
                C501_Service_Household_Id__c = listServiceHouseholds[serviceHouseholdIndex].Id,
                C501_Service_Id__c = listServiceHouseholds[serviceHouseholdIndex].C501_Service_Id__c,
                C501_contact_Id__c = contact.Id
            ));
            serviceHouseholdIndex++;
        }
    }

    //==================== TEST METHOD(s) ======================================
    private static testmethod void CodeCoverageTests() {

        List<Account> accounts = [SELECT Id FROM Account];
        Id masterAccountId = [SELECT Account__c FROM C501_Account_Merge__c LIMIT 1].Account__c;

        //point to our VF page
        PageReference p = new PageReference('Page.MassMergeAccounts');
        p.getParameters().put('Id', masterAccountId);
        Test.setCurrentPageReference(p);
        
        //instantiate the controller for this opp
        C501_CTRL_MassMergeAccounts ctrl = new C501_CTRL_MassMergeAccounts();
        System.AssertEquals(masterAccountId, ctrl.accountFilter.Id);
        System.Assert(ctrl.listSOAccounts.size() > 1);
        System.AssertEquals(accounts.size(), ctrl.listAccounts.size());

        ctrl.accountFilter.Id = null;
        ctrl.ChangeMergeConfidence();
        ctrl.ChangeProgram();
        ctrl.ChangeAccount();
        ctrl.ResetAccounts();
        System.AssertEquals(null, ctrl.listAccounts);
        
        System.Assert(ctrl.listSOPrograms.size() > 1);

        // Check filter by Program
        ctrl.accountFilter.Id = masterAccountId;
        ctrl.serviceHouseholdFilter.C501_Program__c = 'Energy Assistance';
        System.AssertEquals(accounts.size(), ctrl.listAccounts.size());

        // Clear filter
        ctrl.ChangeProgram();
        ctrl.accountFilter.Id = masterAccountId;
        System.AssertEquals(accounts.size(), ctrl.listAccounts.size());
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
        for (Account accountMerge :ctrl.listAccounts) {
            accountMerge.C501_Merge_Action__c = 'Merge';
        }
        ctrl.listAccounts[ctrl.listAccounts.size() - 1].C501_Merge_Action__c = 'Ignore';
        ctrl.SaveAccounts();

        system.debug(ctrl.strSaveResults);
        //System.Assert(ctrl.strSaveResults.startsWith('Error'));
        ctrl.ChangeProgram();
        ctrl.SaveAndCloseAccounts();      
        System.AssertEquals(0, ctrl.numberOfRecordsDirty);  
    }

    private static testMethod void testPageMessagesController() {

        ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.WARNING,'warning'));
        ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.INFO,'info'));
        ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.FATAL,'fatal'));
        ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR,'error'));
        ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.CONFIRM,'confirm'));

        C501_UTIL_PageMessages_CTRL controller = new C501_UTIL_PageMessages_CTRL();
        List<C501_UTIL_PageMessages_CTRL.Message> messages = controller.getPageMessages();

        System.assertEquals(5, messages.size(), 'There should be 5 messages on the page.');

        System.assertEquals(Label.PageMessagesWarning, messages[0].getSeverityLabel(), 'The label should be WARNING.');
        System.assertEquals('', messages[1].getSeverityLabel(), 'The label should be INFO.');
        System.assertEquals(Label.PageMessagesFatal, messages[2].getSeverityLabel(), 'The label should be FATAL.');
        System.assertEquals(Label.PageMessagesError, messages[3].getSeverityLabel(), 'The label should be ERROR.');
        System.assertEquals(Label.PageMessagesConfirm, messages[4].getSeverityLabel(), 'The label should be CONFIRM.');

        System.assertEquals('warning', messages[0].getSeverityTheme(), 'The theme should be warning.');
        System.assertEquals('info', messages[1].getSeverityTheme(), 'The theme should be info.');
        System.assertEquals('error', messages[2].getSeverityTheme(), 'The theme should be fatal.');
        System.assertEquals('error', messages[3].getSeverityTheme(), 'The theme should be error.');
        System.assertEquals('success', messages[4].getSeverityTheme(), 'The theme should be confirm.');
    }
}