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
        if (id != null && id != '') accountId = id;
        
        id = ApexPages.currentPage().getParameters().get('programName');
        if (id != null && id != '') programName = id;

        // Get list of fields from fieldset
        listStrFields = new List<String>();
        for (Schema.FieldSetMember f : SObjectType.Account.FieldSets.MassMergeAccounts.getFields()) {
            listStrFields.add(f.getFieldPath());
        }

        // Required fields
        listStrFields.add('accountId');
        listStrFields.add('programName');
    }   
    
    // holds the currently selected Account in the Account lookup
    global ID accountId { get; set; }

    // the list of Programs to put in the Program dropdown
    global list<SelectOption> listSOAccounts {
        get {
            if (listSOAccounts == null )
                listSOAccounts = c501MassMerge_SharedCode.listSOAccountsWithConfidence(programName, accountFilter.C501_Merge_Confidence_From__c, accountFilter.C501_Merge_Confidence_To__c);

            return listSOAccounts;
        }

        set;
        }
    
    // holds the currently select Owner in the Owner dropdown
    global ID programName { get; set; }
    
    // the list of Owners to put in the dropdown
    global list<SelectOption> listSOServicePrograms {
        get {
            if (listSOServicePrograms == null && accountId != null) {
                listSOServicePrograms = c501MassMerge_SharedCode.listSOServiceProgramsWithConfidence(accountId, accountFilter.C501_Merge_Confidence_From__c, accountFilter.C501_Merge_Confidence_To__c);
            }
            return listSOServicePrograms;
        }
        
        set;
    }
    
    // Confidence to filter the list of accounts
    global Account accountFilter {
        get {
            if (accountFilter == null) {
                accountFilter = new Account();
                
                accountFilter.C501_Merge_Confidence_From__c = 1.0;
                accountFilter.C501_Merge_Confidence_To__c = 0.9;
            }
            return accountFilter;
        }
        set;
    }

    // the user has changed the Account dropdown
    global virtual PageReference ChangeAccount() {
        // clear out all state that is specific to the Owner
        listAccounts = null;
        strSaveResults = null;
        return null;
    }

    // the user has changed the Confidence query
    global virtual PageReference ChangeMergeConfidence() {
        // clear out all state that is specific to the Date
        listSOAccounts = null;
        listSOServicePrograms = null;
        listAccounts = null;
        strSaveResults = null;
        return null;
    }

    // the user has changed the Program dropdown
    global virtual PageReference ChangeProgram() {

        // clear out all state that is specific to the Program
        listSOServicePrograms = null;
        accountFilter.C501_Merge_Program__c = null;
        ChangeAccount();
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

        // if they haven't yet picked a program
        if (accountId == null) return;           
        
        // find the existing owners
        // we need to use dynamic soql to pick up all custom fields we don't know about
        string strSoql = 
            'select ' + String.join(listStrFields, ',');

        strSoql += ' from Account where C501_Merge_Targets__c > 0 ';
        
        if (accountFilter.C501_Merge_Program__c != null)
            strSoql += ' and (C501_Merge_Program__c = :accountFilter.C501_Merge_Program__c or C501_Merge_Program__c = null) ';

        if (accountFilter.C501_Merge_Confidence_From__c != null) {
            strSoql += ' and C501_C501_Merge_Confidence__c >= :accountFilter.C501_Merge_Confidence_From__c ';
        }
        if (accountFilter.C501_Merge_Confidence_To__c != null) {
            strSoql += ' and C501_C501_Merge_Confidence__c <= :accountFilter.C501_Merge_Confidence_To__c ';
        }

        strSoql += ' order by Account.Name ASC NULLS FIRST';
        
        listAccounts = Database.Query(strSoql);
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
            list<Account> listAccountsUpdate = new list<Account>();

            for (Account opp : listAccounts) {
                if (opp.Id != null) {
                    // we couldn't reliably mark dirty records in all scenarios,
                    // so we've decided it is better to always update all records.
                    //if (setAccountsIdDirty.contains(opp.Id)) 
                    listAccountsUpdate.add(opp);
                }
            }
            
            update listAccountsUpdate;
           
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
        if (programName != null)
            idRedirect = programName;
        else
            idRedirect = accountId;
        
        // trigger our redirect component to redirect using javascript.
        redirect = true;
        return null;
    }
    
    // this was a testmethod which can't be compiled in this class under api 31.  
    // but because it was marked global, it could not be completely removed.
    global static void CodeCoverageTests() {}
}