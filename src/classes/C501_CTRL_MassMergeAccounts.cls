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

global virtual with sharing class C501_CTRL_MassMergeAccounts {

    global integer cEmptyAccountRecords {
        get {
            return 1;
        }
    }
    
    private C501_MassMerge_SharedCode c501MassMerge_SharedCode;
    private List<String> listStrFields;
    
    global boolean redirect { get; private set; }
    global ID idRedirect { get; private set; }
    
    // constructor
    global C501_CTRL_MassMergeAccounts() {
        redirect = false;
        c501MassMerge_SharedCode = new C501_MassMerge_SharedCode();
        
        // handle optional parameters (must use string, not ID, to handle null)
        string id = ApexPages.currentPage().getParameters().get('id');
        if (id != null && id != '') accountFilter.Id = id;
        
        // Get list of fields from fieldset
        listStrFields = new List<String>();
        for (Schema.FieldSetMember f : SObjectType.Account.FieldSets.MassMergeAccounts.getFields()) {
            listStrFields.add(f.getFieldPath());
        }

        // Required fields
        listStrFields.add('Id');
        listStrFields.add('C501_Merge_Action__c');
    }   
    
    global list<SelectOption> listSOAccounts {
        get {
            if (listSOAccounts == null )
                listSOAccounts = c501MassMerge_SharedCode.listSOAccountsWithConfidence(serviceHouseholdFilter.C501_Program__c, accountFilter.C501_Merge_Confidence_From__c, accountFilter.C501_Merge_Confidence_To__c);

            return listSOAccounts;
        }

        set;
        }

    global list<SelectOption> listSOPrograms {
        get {
            if (listSOPrograms == null ) {
                Schema.DescribeFieldResult fieldResult = C501_Service_Household__c.C501_Program__c.getDescribe();
                List<Schema.PicklistEntry> picklistValues = fieldResult.getPicklistValues();

                listSOPrograms = new List<System.SelectOption>();
                listSOPrograms.add(new SelectOption('', ''));

                for (Schema.PicklistEntry picklistValue :picklistValues) {
                    listSOPrograms.add(new SelectOption(picklistValue.getLabel(), picklistValue.getValue()));
                }
            }

            return listSOPrograms;
        }

        set;
        }

    global C501_Service_Household__c serviceHouseholdFilter {
        get {
            if (serviceHouseholdFilter == null) {
                serviceHouseholdFilter = new C501_Service_Household__c();
            }
            return serviceHouseholdFilter;
        }
        set;
    }

    // Confidence to filter the list of accounts
    global Account accountFilter {
        get {
            if (accountFilter == null) {
                accountFilter = new Account();
                
                accountFilter.C501_Merge_Confidence_From__c = 90.0;
                accountFilter.C501_Merge_Confidence_To__c = 100.0;
            }
            return accountFilter;
        }
        set;
    }

    // the user has changed the Account dropdown
    global virtual PageReference ChangeAccount() {

        listAccounts = null;
        strSaveResults = null;

        return null;
    }

    // the user has changed the Program dropdown
    global virtual PageReference ChangeProgram() {

        listSOAccounts = null;
        accountFilter.Id = null;
        listAccounts = null;
        strSaveResults = null;

        return null;
    }

    // the user has changed the Confidence query
    global virtual PageReference ChangeMergeConfidence() {

        listSOAccounts = null;
        accountFilter.Id = null;
        listAccounts = null;
        strSaveResults = null;

        return null;
    }

    global virtual void ResetAccounts() {

        listSOAccounts = null;
        accountFilter.Id = null;
        listAccounts = null;
    }

    // status string for reporting the results of saving.
    global String strSaveResults { get; set; }
      
    // The list of Accounts.
    global list<Account> listAccounts {
        get {
            if (listAccounts == null) {
                FillListAccounts();
            }
            return listAccounts;
        }
        
        set;
    }
        
    // helper function that the client can override, to query for the appropriate fields in Accounts.
    global virtual void FillListAccounts() {

        // if they haven't yet picked an account
        if (accountFilter.Id == null) return;           
        
		Map<Id,C501_Account_Merge__c> accountsMerge = new Map<Id,C501_Account_Merge__c>();
        accountsMerge.put(accountFilter.Id, new C501_Account_Merge__c(
            Merge_Confidence__c = 100.0));
		for(C501_Account_Merge__c accountMerge : [
			SELECT Id, Account__c, Merge_Target_Account__c, Merge_Confidence__c, Merge_Action__c, Merge_Metric__c
			FROM C501_Account_Merge__c
			WHERE Account__c = :accountFilter.Id AND isDeleted = false]) {
        		accountsMerge.put(accountMerge.Merge_Target_Account__c, new C501_Account_Merge__c(
                    Id = accountMerge.Id,
                    Merge_Action__c = accountMerge.Merge_Action__c,
                    Merge_Confidence__c = accountMerge.Merge_Confidence__c,
                    Merge_Target_Account__c = accountMerge.Merge_Target_Account__c,
                    Account__c = accountMerge.Account__c,
                    Merge_Metric__c = accountMerge.Merge_Metric__c
                ));
		}

        string strSoql = 
            'select ' + String.join(listStrFields, ',');

        Set<Id> accountsMergeIds = accountsMerge.keySet();
        strSoql += ' from Account where Id in :accountsMergeIds';
        
/*        if (accountFilter.C501_Merge_Program__c != null)
            strSoql += ' and (C501_Merge_Program__c = :accountFilter.C501_Merge_Program__c or C501_Merge_Program__c = null) ';

        if (accountFilter.C501_Merge_Confidence_From__c != null) {
            strSoql += ' and C501_C501_Merge_Confidence__c >= :accountFilter.C501_Merge_Confidence_From__c ';
        }
        if (accountFilter.C501_Merge_Confidence_To__c != null) {
            strSoql += ' and C501_C501_Merge_Confidence__c <= :accountFilter.C501_Merge_Confidence_To__c ';
        }
*/
        strSoql += ' order by Account.Name ASC NULLS FIRST';
        
        listAccounts = Database.Query(strSoql);

        // Get Merge Metrics
        Map<Id, String> mergeMetrics = new Map<Id, String>();
        for(C501_Merge_Metric__c mergeMetric : [
            SELECT Id, Name
            FROM C501_Merge_Metric__c]) {
                mergeMetrics.put(mergeMetric.Id, mergeMetric.Name);
        }

        for ( Account account :listAccounts ) {
            if (accountsMerge.containsKey(account.Id)) {
                C501_Account_Merge__c mergeAccount = accountsMerge.get(account.Id);
                account.C501_Merge_Action__c = mergeAccount.Merge_Action__c;
                account.C501_Merge_Confidence__c = mergeAccount.Merge_Confidence__c;
                account.C501_Merge_Target__c = mergeAccount.Merge_Target_Account__c;
                account.C501_Merge_Account__c = mergeAccount.Id;

                if (mergeMetrics.containsKey(mergeAccount.Merge_Metric__c)) {
                    account.C501_Merge_Metric_Name__c = mergeMetrics.get(mergeAccount.Merge_Metric__c);
                }
                else {
                    account.C501_Merge_Metric_Name__c = 'Selected Household';
                }
            }
        }
    }
    
    global Boolean fHasListAccounts {
        get {
            return listAccounts != null && listAccounts.size() > 0;
        }
    }     
 
    // used to track the Id's of all Account records that get modified.
    global Set<ID> setAccountsIdDirty {
        get {
            if (setAccountsIdDirty == null) {
                setAccountsIdDirty = new Set<ID>();
            }
            return setAccountsIdDirty;
        }
        set;
    }
    
    // to allow vf page to see how many Account records are dirty
    global Integer numberOfRecordsDirty {
        get { 
            if (setAccountsIdDirty == null)
                return 0;
            else
                return setAccountsIdDirty.size();
        }
    }
    
    // this gets called whenever a field in the Accounts datatable is modified.
    // use this to remember which existing Accounts records have been modified.
    global virtual PageReference AccountsRecordModified() {
        String strId = ApexPages.currentPage().getParameters().get('usersIdDirtied');
        if (strId != null && strId != '') setAccountsIdDirty.add(strId);
        return null;
    }
    
    //save the Accounts created or modified
    global virtual PageReference SaveAccounts() {
        
        if (listAccounts == null) return null;
        
        strSaveResults = null;
        
        try {
            // Step 1: Update accounts with Merge Action
            list<Account> listAccountsMerge = new list<Account>();
            list<C501_Account_Merge__c> listAccountsMergeIgnore = new list<C501_Account_Merge__c>();
            for (Account account : listAccounts) {

                system.debug('C501_CTRL_MassMergeAccounts::SaveAccounts Update Merge Action - account.Id: ' + account.Id 
                    + ' account.C501_Merge_Action__c: ' + account.C501_Merge_Action__c);

                if (account.Id != null && account.C501_Merge_Action__c == 'Merge') {

                    // we couldn't reliably mark dirty records in all scenarios,
                    // so we've decided it is better to always update all records.
                    //if (setAccountsIdDirty.contains(account.Id)) 
                    listAccountsMerge.add(account);
                }

                if (account.Id != null && account.C501_Merge_Action__c == 'Ignore') {

                    // we couldn't reliably mark dirty records in all scenarios,
                    // so we've decided it is better to always update all records.
                    //if (setAccountsIdDirty.contains(account.Id)) 
                    listAccountsMergeIgnore.add(new C501_Account_Merge__c(
                        Id = account.C501_Merge_Account__c,
                        Account__c = account.Id,
                        Merge_Target_Account__c = account.C501_Merge_Target__c,
                        Merge_Action__c = account.C501_Merge_Action__c
                    ));
                }
            }

            Integer recordsUpdated = listAccountsMergeIgnore.size() + listAccountsMerge.size();
            
            if (!listAccountsMergeIgnore.isEmpty()) {
                update listAccountsMergeIgnore;
            }

            if (listAccountsMerge.size() >= 2) {
                c501MassMerge_SharedCode.AccountsMerge(listAccountsMerge);
            }

            strSaveResults = recordsUpdated + ' ' + Label.labelMassMergeSaveSuccess;
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.CONFIRM, strSaveResults));

            // successful save, so clear out dirty list
            setAccountsIdDirty = null;

            // Refresh Account and Account Table
            ResetAccounts();

            return null;            

        } catch (Exception e) {
            strSaveResults = Label.labelMassMergeErrorOnSave;
            ApexPages.addMessages(e); 
            return null;
        }
    }

    //save the Accounts modified, and then close the page.
    global virtual PageReference SaveAndCloseAccounts() {
        SaveAccounts();
        if (ApexPages.hasMessages(ApexPages.Severity.ERROR) ||
           ApexPages.hasMessages(ApexPages.Severity.FATAL) ||
            ApexPages.hasMessages(ApexPages.Severity.WARNING)) {
                return null; // don't close window.
        }
        return Cancel();    
    }
    
    // user wants to close this page
    global virtual PageReference Cancel() {
        // figure out which object to return to.
        idRedirect = accountFilter.Id;
        
        // trigger our redirect component to redirect using javascript.
        redirect = true;
        return null;
    }
    
    // this was a testmethod which can't be compiled in this class under api 31.  
    // but because it was marked global, it could not be completely removed.
    global static void CodeCoverageTests() {}
}