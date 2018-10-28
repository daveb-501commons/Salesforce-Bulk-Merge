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
        
		Map<Id,Decimal> accountsMerge = new Map<Id,Decimal>();
        accountsMerge.put(accountFilter.Id, 100.0);
		for(C501_Account_Merge__c accountMerge : [
			SELECT Merge_Target_Account__c, Merge_Confidence__c
			FROM C501_Account_Merge__c
			WHERE Account__c = :accountFilter.Id AND isDeleted = false]) {
        		accountsMerge.put(accountMerge.Merge_Target_Account__c, accountMerge.Merge_Confidence__c);
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

        for ( Account account :listAccounts ) {
            if (accountsMerge.containsKey(account.Id)) {
                account.C501_Merge_Confidence__c = accountsMerge.get(account.Id);
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
            list<Account> listAccountsUpdate = new list<Account>();
            list<Account> listAccountsMerge = new list<Account>();
            for (Account account : listAccounts) {

                system.debug('C501_CTRL_MassMergeAccounts::SaveAccounts Update Merge Action - account.Id: ' + account.Id 
                    + ' account.C501_Merge_Action__c: ' + account.C501_Merge_Action__c);

                if (account.Id != null && (account.C501_Merge_Action__c != '--None--' || String.isBlank(account.C501_Merge_Action__c))) {

                    // we couldn't reliably mark dirty records in all scenarios,
                    // so we've decided it is better to always update all records.
                    //if (setAccountsIdDirty.contains(account.Id)) 
                    listAccountsUpdate.add(account);
                }
                
                if (account.Id != null && account.C501_Merge_Action__c == 'Merge') {

                    // we couldn't reliably mark dirty records in all scenarios,
                    // so we've decided it is better to always update all records.
                    //if (setAccountsIdDirty.contains(account.Id)) 
                    listAccountsMerge.add(account);
                }
            }
            
            if (!listAccountsUpdate.isEmpty()) {
                update listAccountsUpdate;
            }

            // Get related Service Households
            Map<Id, List<Id>> serviceHouseholds = new Map<Id, List<Id>>();
            for(C501_Service_Household__c serviceHousehold : [
                SELECT Id, C501_Household__c
                FROM C501_Service_Household__c
                WHERE C501_Household__c in :listAccountsMerge]) {
                    if (serviceHouseholds.containsKey(serviceHousehold.C501_Household__c)) {
                        List<Id> services = serviceHouseholds.remove(serviceHousehold.C501_Household__c);
                        services.add(serviceHousehold.Id);
                        serviceHouseholds.put(serviceHousehold.C501_Household__c, services);
                    }
                    else {
                        serviceHouseholds.put(serviceHousehold.C501_Household__c, new List<Id> {serviceHousehold.Id});
                    }
            }

            // Step 2: Check to Merge accounts
            list<C501_Service_Household__c> listServiceHouseholdsUpdate = new list<C501_Service_Household__c>();
            list<Account> listAccountsDelete = new list<Account>();
            if (listAccountsMerge.size() >= 2) {
                Account masterAccount = listAccountsMerge.remove(1);
                for (Account account : listAccountsMerge) {

                    system.debug('C501_CTRL_MassMergeAccounts::SaveAccounts Merge Accounts - account.Id: ' + account.Id 
                        + ' account.C501_Merge_Action__c: ' + account.C501_Merge_Action__c);

                    // Reassign Service Households
                    if (serviceHouseholds.containsKey(account.Id)) {
                        List<Id> services = serviceHouseholds.remove(account.Id);
                        for (Id serviceId : services) {
                            listServiceHouseholdsUpdate.add(new C501_Service_Household__c(
                                Id = serviceId,
                                C501_Household__c = masterAccount.Id
                            ));
                        }
                    }

                    // Reassign Contacts
                    // TBD - Merge contacts and seperate household for each contact not merge

                    // Reassign Account Merges
                    // TBD - except the one related to master account
                    // Update Merge Metric Total_Merge__c for each merged household (other than master)

                    // Reassign Addresses
                    // TBD - make sure not creating duplicates

                    // Reassign Client Visits (Intake)
                    // TBD

                    // Delete Account
                    listAccountsDelete.add(account);
                }
            }

            if (!listServiceHouseholdsUpdate.isEmpty()) {
                update listServiceHouseholdsUpdate;
            }

            if (!listAccountsDelete.isEmpty()) {
                //delete listAccountsDelete;
            }
           
            strSaveResults = listAccountsUpdate.size() + ' ' + Label.labelMassMergeSaveSuccess;
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.CONFIRM, strSaveResults));

            // successful save, so clear out dirty list
            setAccountsIdDirty = null;

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