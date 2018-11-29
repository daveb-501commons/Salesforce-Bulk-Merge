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

global with sharing class C501_MassMerge_SharedCode { 

    public class C501_CTRL_MassMergeAccountsException extends Exception {}

    global void AccountsMerge(List<Account> listAccountsMerge) {

        // Get related Service Households per Account
        C501_Service_Household__c controllingServiceHousehold = null;
        Id masterAccountId = null;
        C501_Service_Household__c controllingServiceHouseholdNotActive = null;
        Id masterAccountIdNotActive = null;
        Map<Id, List<Id>> relatedServiceHouseholds = new Map<Id, List<Id>>();
        for(C501_Service_Household__c relatedServiceHousehold : [
            SELECT Id, C501_Household__c, C501_Start_Date__c, C501_IsActive__c
            FROM C501_Service_Household__c
            WHERE C501_Household__c in :listAccountsMerge]) {

                if (relatedServiceHousehold.C501_IsActive__c) {

                    // Check for most recent active Service Household
                    if (controllingServiceHousehold == null || controllingServiceHousehold.C501_Start_Date__c < relatedServiceHousehold.C501_Start_Date__c) {
                        masterAccountId = relatedServiceHousehold.C501_Household__c;
                        controllingServiceHousehold = relatedServiceHousehold;
                    }
                }
                else {

                    // Check for most recent not active Service Household
                    if (controllingServiceHouseholdNotActive == null || controllingServiceHouseholdNotActive.C501_Start_Date__c < relatedServiceHousehold.C501_Start_Date__c) {
                        masterAccountIdNotActive = relatedServiceHousehold.C501_Household__c;
                        controllingServiceHouseholdNotActive = relatedServiceHousehold;
                    }
                }

                if (relatedServiceHouseholds.containsKey(relatedServiceHousehold.C501_Household__c)) {

                    List<Id> services = relatedServiceHouseholds.remove(relatedServiceHousehold.C501_Household__c);
                    services.add(relatedServiceHousehold.Id);
                    relatedServiceHouseholds.put(relatedServiceHousehold.C501_Household__c, services);
                }
                else {

                    relatedServiceHouseholds.put(relatedServiceHousehold.C501_Household__c, new List<Id> {relatedServiceHousehold.Id});
                }
        }

        if (masterAccountId == null && masterAccountIdNotActive != null) {
            masterAccountId = masterAccountIdNotActive;
            controllingServiceHousehold = controllingServiceHouseholdNotActive;
        }

        if (masterAccountId == null) {
            throw new C501_CTRL_MassMergeAccountsException('C501_CTRL_MassMergeAccounts::SaveAccounts - Merge Setup Error - Account & Service Household Issue.  Account not found');
        }

        Integer accountMergeIndex = listAccountsMerge.size() - 1;
        while (accountMergeIndex-- > 0) {
            Account accountMerge = listAccountsMerge[accountMergeIndex];
            if (accountMerge.Id == masterAccountId) {
                listAccountsMerge.remove(accountMergeIndex);
                break;
            }
        }

        // Get related Client Visits per Account
        Map<Id, List<Id>> relatedClientVisits = new Map<Id, List<Id>>();
        for(Client_Visit__c relatedClientVisit : [
            SELECT Id, C501_IS_Household__c
            FROM Client_Visit__c
            WHERE C501_IS_Household__c in :listAccountsMerge]) {
                if (relatedClientVisits.containsKey(relatedClientVisit.C501_IS_Household__c)) {
                    List<Id> related = relatedClientVisits.remove(relatedClientVisit.C501_IS_Household__c);
                    related.add(relatedClientVisit.Id);
                    relatedClientVisits.put(relatedClientVisit.C501_IS_Household__c, related);
                }
                else {
                    relatedClientVisits.put(relatedClientVisit.C501_IS_Household__c, new List<Id> {relatedClientVisit.Id});
                }
        }

        // Get related Account Merges per Account
        Map<Id, List<Id>> relatedAccountMerges = new Map<Id, List<Id>>();
        for(C501_Account_Merge__c relatedAccountMerge : [
            SELECT Id, Account__c
            FROM C501_Account_Merge__c
            WHERE Account__c in :listAccountsMerge]) {
                if (relatedAccountMerges.containsKey(relatedAccountMerge.Account__c)) {
                    List<Id> related = relatedAccountMerges.remove(relatedAccountMerge.Account__c);
                    related.add(relatedAccountMerge.Id);
                    relatedAccountMerges.put(relatedAccountMerge.Account__c, related);
                }
                else {
                    relatedAccountMerges.put(relatedAccountMerge.Account__c, new List<Id> {relatedAccountMerge.Id});
                }
        }

        // Get Merge Metrics
        Map<String, C501_Merge_Metric__c> mergeMetrics = new Map<String, C501_Merge_Metric__c>();
        for(C501_Merge_Metric__c mergeMetric : [
            SELECT Id, Name, Total_Merge__c
            FROM C501_Merge_Metric__c]) {
                mergeMetrics.put(mergeMetric.Name, mergeMetric);
        }

        // Step 2: Check to Merge accounts
        list<C501_Service_Household__c> listServiceHouseholdsUpdate = new list<C501_Service_Household__c>();
        list<C501_Account_Merge__c> listAccountMergesUpdate = new list<C501_Account_Merge__c>();
        list<Client_Visit__c> listClientVisitsUpdate = new list<Client_Visit__c>();
        list<C501_Account_Merge__c> listAccountMergesDelete = new List<C501_Account_Merge__c>();

        for (Account account : listAccountsMerge) {

            system.debug('C501_CTRL_MassMergeAccounts::SaveAccounts Merge Accounts - account.Id: ' + account.Id 
                + ' account.C501_Merge_Action__c: ' + account.C501_Merge_Action__c);

            // Reassign Service Households
            if (relatedServiceHouseholds.containsKey(account.Id)) {
                List<Id> services = relatedServiceHouseholds.remove(account.Id);
                for (Id serviceId : services) {
                    listServiceHouseholdsUpdate.add(new C501_Service_Household__c(
                        Id = serviceId,
                        C501_Household__c = masterAccountId,
                        C501_Trigger_Ignore_Change__c = true
                    ));
                }
            }

            // Reassign Account Merges
            if (relatedAccountMerges.containsKey(account.Id) && account.Id <> masterAccountId) {
                List<Id> related = relatedAccountMerges.remove(account.Id);
                for (Id objectId : related) {
                    listAccountMergesUpdate.add(new C501_Account_Merge__c(
                        Id = objectId,
                        Account__c = masterAccountId
                    ));
                }
            }

            // Reassign Client Visits (Intake)
            if (relatedClientVisits.containsKey(account.Id)) {
                List<Id> related = relatedClientVisits.remove(account.Id);
                for (Id objectId : related) {
                    listClientVisitsUpdate.add(new Client_Visit__c(
                        Id = objectId,
                        C501_IS_Household__c = masterAccountId
                    ));
                }
            }

            // Update Merge Metric
            if (mergeMetrics.containsKey(account.C501_Merge_Metric_Name__c)) {
                C501_Merge_Metric__c mergeMetric = mergeMetrics.remove(account.C501_Merge_Metric_Name__c);
                mergeMetric.Total_Merge__c = (mergeMetric.Total_Merge__c == null) ? 1 : mergeMetric.Total_Merge__c + 1;
                mergeMetrics.put(account.C501_Merge_Metric_Name__c, mergeMetric);
            }

            // Delete Account Merge
            if (account.C501_Merge_Account__c != null && !String.isBlank(account.C501_Merge_Account__c)) {
                listAccountMergesDelete.add(new C501_Account_Merge__c (
                    Id = account.C501_Merge_Account__c
                ));
            }
        }

        if (!listServiceHouseholdsUpdate.isEmpty()) {
            update listServiceHouseholdsUpdate;
        }
        if (!listClientVisitsUpdate.isEmpty()) {
            update listClientVisitsUpdate;
        }
        if (!listAccountMergesUpdate.isEmpty()) {
            update listAccountMergesUpdate;
        }

        ContactsMerge(masterAccountId, listAccountsMerge);

        if (!listAccountMergesDelete.isEmpty()) {
            delete listAccountMergesDelete;
        }

        // Update Merge Counts
        List<C501_Merge_Metric__c> listMergeMetrics = mergeMetrics.values();
        if (!listMergeMetrics.isEmpty()) {
            update listMergeMetrics;
        }
    }

    global void ContactsMerge(Id masterAccountId, List<Account> mergeAccounts) {

        List<Contact> mergeContacts = [
            SELECT Id, AccountId, Birthdate, FirstName, Phone
            FROM Contact
            WHERE AccountId in :mergeAccounts];

        List<Id> mergeContactIds = new List<Id>();
        for (Contact mergeContact :mergeContacts) {
            mergeContactIds.add(mergeContact.Id);
        }

        List<C501_Service_Contact__c> mergeServiceContacts = [
            SELECT Id, C501_Contact__c
            FROM C501_Service_Contact__c
            WHERE C501_Contact__c in :mergeContactIds];

        List<Contact> masterContacts = [
            SELECT Id, AccountId, Birthdate, FirstName, C501_Is_In_Household__c
            FROM Contact
            WHERE AccountId = :masterAccountId];

        List<Id> masterContactIds = new List<Id>();
        for (Contact masterContact :masterContacts) {
            masterContactIds.add(masterContact.Id);
        }

        List<Id> allContacttIds = new List<Id>(mergeContactIds);
        allContacttIds.addAll(masterContactIds);
        Set<String> uniqueOtherNames = new Set<String>();
        List<C501_Other_Name__c> contactOtherNames = new List<C501_Other_Name__c>();
        for(C501_Other_Name__c contactOtherName : [
            SELECT Id, C501_Contact__c, C501_Other_Name__c
            FROM C501_Other_Name__c
            WHERE C501_Contact__c in :allContacttIds]) {
                contactOtherNames.add(contactOtherName);
                uniqueOtherNames.add(contactOtherName.C501_Contact__c + contactOtherName.C501_Other_Name__c);
            }

        List<Contact> listDeleteContacts = new List<Contact>();
        List<C501_Service_Contact__c> listUpdateServiceContacts = new List<C501_Service_Contact__C>();
        List<C501_Other_Name__c> listUpdateContactOtherNames = new List<C501_Other_Name__c>();
        for(Contact masterContact :masterContacts) {

            for (contact mergeContact : mergeContacts) {

                // Match based on Birthdate and Firstname (in case of Twins).  Don't match Last Name in case of name change
                if (masterContact.Birthdate == mergeContact.Birthdate
                    && masterContact.FirstName == mergeContact.FirstName
                    && masterAccountId != mergeContact.AccountId
                    && (masterContact.C501_Is_In_Household__c || !masterContact.C501_Is_In_Household__c && !mergeContact.C501_Is_In_Household__c)) {
                    
                    // Reassign any service contacts
                    for (C501_Service_Contact__c serviceContact :mergeServiceContacts) {
                        if (serviceContact.C501_Contact__c == mergeContact.Id) {
                            listUpdateServiceContacts.add( new C501_Service_Contact__c (
                                Id = serviceContact.Id,
                                C501_Contact__c = masterContact.Id,
                                C501_Trigger_Ignore_Change__c = true
                            ));
                        }
                    }

                    // Reassign any Contact Other Names
                    for (C501_Other_Name__c contactOtherName :contactOtherNames) {
                        if (contactOtherName.C501_Contact__c == mergeContact.Id) {

                            // Add Other Name if doesn't already exist
                            if (!uniqueOtherNames.contains(masterContact.Id + contactOtherName.C501_Other_Name__c)) {
                                listUpdateContactOtherNames.add( new C501_Other_Name__c (
                                    Id = contactOtherName.Id,
                                    C501_Contact__c = masterContact.Id
                                ));
                            }
                        }
                    }

                    mergeContact.C501_Trigger_Ignore_Change__c = true;
                    listDeleteContacts.add(mergeContact);
                }
            }
        }        

        if (!listUpdateServiceContacts.isEmpty()) {
            update listUpdateServiceContacts;
        }

        if (!listUpdateContactOtherNames.isEmpty()) {
            update listUpdateContactOtherNames;
        }

        if (!listDeleteContacts.isEmpty()) {
            delete listDeleteContacts;
        }

        Map<Id, Contact> accountsWithContacts = new Map<Id, Contact>();
        for(Contact contact : [
            SELECT AccountId, Id, Phone
            FROM Contact
            WHERE AccountId in :mergeAccounts]) {
                accountsWithContacts.put(contact.AccountId, contact);
        }

        List<Account> deleteAccountsNoContacts = new List<Account>();
        for (Account mergeAccount :mergeAccounts) {
            if (!accountsWithContacts.containsKey(mergeAccount.Id)) {
                mergeAccount.C501_Trigger_Ignore_Change__c = true;
                deleteAccountsNoContacts.add(mergeAccount);
            }
        }

        // Hack - for some reason there is a Change Request on the Account.  A change is causing a Change Request making it so can't delete the Account
        List<C501_Service_Household__c> deleteServicesOnAccountsNoContacts = new List<C501_Service_Household__c>();
        for (C501_Service_Household__c deleteSH : [
            SELECT Id
            FROM C501_Service_Household__c
            WHERE Name like '%Change Request%' and C501_Household__c in :deleteAccountsNoContacts]) {
                deleteServicesOnAccountsNoContacts.add(new C501_Service_Household__c (
                    Id = deleteSH.Id
                ));
        }

        if (!deleteServicesOnAccountsNoContacts.isEmpty()) {
            delete deleteServicesOnAccountsNoContacts;
        }

        if (!deleteAccountsNoContacts.isEmpty()) {
            delete deleteAccountsNoContacts;
        }
    }

    // the list of Accounts
    global list<SelectOption> listSOAccountsWithConfidence(String programName, Decimal fromMergeConfidence, Decimal toMergeConfidence) {

        system.debug('C501_MassMerge_SharedCode::listSOAccountsWithConfidence - programName: ' + programName 
            + ' fromMergeConfidence: ' + fromMergeConfidence.toPlainString()
            + ' toMergeConfidence: ' + toMergeConfidence.toPlainString());

        Set<String> setSOUnique = new Set<String>();
        List<SelectOption> listSO = new List<SelectOption>();
        listSO.add(new SelectOption('', ''));

        if (String.isBlank(programName)) {
            for (AggregateResult result : [
                select Account__c, Account__r.Name from C501_Account_Merge__c
                where Merge_Confidence__c >= :fromMergeConfidence
                    and Merge_Confidence__c <= :toMergeConfidence
                    and Merge_Action__c <> 'Ignore' 
                group by Account__c, Account__r.Name
                limit 999]) {
                    listSO.add(new SelectOption(result.get('Account__c').toString(),
                        result.get('Name').toString()));
                }
        }
        else {
            for (AggregateResult result : [
                select Account__c, Account__r.Name from C501_Account_Merge__c
                where Merge_Confidence__c >= :fromMergeConfidence
                    and Merge_Confidence__c <= :toMergeConfidence
                    and Merge_Action__c <> 'Ignore'
                    and Account__c in (SELECT C501_Household__c FROM C501_Service_Household__c WHERE C501_Program__c = :programName) 
                group by Account__c, Account__r.Name
                limit 999]) {
                    if (!setSOUnique.contains(result.get('Account__c').toString())) {
                        setSOUnique.add(result.get('Account__c').toString());
                        listSO.add(new SelectOption(result.get('Account__c').toString(),
                            result.get('Name').toString()));
                    }
                }

            // Query based on Merge_Target_Account__c seperately because nested semi-join not allowed in SOQL
            for (AggregateResult result : [
                select Merge_Target_Account__c, Merge_Target_Account__r.Name, Account__c from C501_Account_Merge__c
                where Merge_Confidence__c >= :fromMergeConfidence
                    and Merge_Confidence__c <= :toMergeConfidence
                    and Merge_Action__c <> 'Ignore'
                    and Merge_Target_Account__c in (SELECT C501_Household__c FROM C501_Service_Household__c WHERE C501_Program__c = :programName)
                group by Merge_Target_Account__c, Merge_Target_Account__r.Name, Account__c
                limit 999]) {
                    if (!setSOUnique.contains(result.get('Account__c').toString())) {
                        if (setSOUnique.size() >= 999 || listSO.size() >= 999) {
                            break;
                        }
                        setSOUnique.add(result.get('Account__c').toString());
                        listSO.add(new SelectOption(result.get('Account__c').toString(),
                            result.get('Name').toString()));
                    }
                }
        }

        List<SelectOption> listSOSorted = new List<SelectOption>();
        listSOSorted = selectOptionSortByLabel(listSO);

        return listSOSorted;
    }

    /******************************************************************************************************
    * @description String helper property for getNamespace() method.
    *******************************************************************************************************/
    private static string plainNamespace;

    /*******************************************************************************************************
    * @description Finds the namespace for the current context.
    * @return string The current namespace as a string, or a blank string if we're not in a namespaced context.
    ********************************************************************************************************/
    public static string getNamespace() {
        if (plainNamespace == null) {
            string withDotNotation = C501_MassMerge_SharedCode.class.getName();

            if (withDotNotation.contains('.')) {
                plainNamespace = withDotNotation.substringBefore('.');
            } else {
                plainNamespace = '';
            }
        }
        return plainNamespace;
    }

    /*
        @Param:List of selectOption to be sort.
        @Return: Sorted list of selectOptions by Label
    */
    public static list<selectOption> selectOptionSortByLabel(list<selectOption>
                                                            selectOptionsToSort) {
        if(selectOptionsToSort == null || selectOptionsToSort.size() <= 1){
            return selectOptionsToSort;
        }
        List<SelectOption> lessSelectOption = new List<SelectOption>();
        List<SelectOption> greaterSelectOption = new List<SelectOption>();
        integer pivot = selectOptionsToSort.size() / 2;
        
        //save the pivot and remove it from the selectOption list
        SelectOption pivotValue = selectOptionsToSort[pivot];
        selectOptionsToSort.remove(pivot);
        for(selectOption SO : selectOptionsToSort){
            if(SO.getLabel() <= pivotValue.getLabel()){
                lessSelectOption.add(SO);
            }else if(SO.getLabel() > pivotValue.getLabel()){
                greaterSelectOption.add(SO);   
            }
        }
        list<selectOption> sortedSelectOptions = new list<selectOption>(); 
        sortedSelectOptions.addAll(selectOptionSortByLabel(lessSelectOption));
        sortedSelectOptions.add(pivotValue);
        sortedSelectOptions.addAll(selectOptionSortByLabel(greaterSelectOption));
        return SortedSelectOptions;
    }

    /*
        @Param:List of selectOption to be sort.
        @Return: Sorted list of selectOptions by Value
    */
    public static list<selectOption> selectOptionSortByValue(list<selectOption>
                                                            selectOptionsToSort){
        if(selectOptionsToSort == null || selectOptionsToSort.size() <= 1){
            return selectOptionsToSort;
        }       
        List<SelectOption> lessSelectOption = new List<SelectOption>();
        List<SelectOption> greaterSelectOption = new List<SelectOption>();
        integer pivot = selectOptionsToSort.size() / 2;
         
        //save the pivot and remove it from the selectOption list
        SelectOption pivotValue = selectOptionsToSort[pivot]; 
        selectOptionsToSort.remove(pivot);
        for(selectOption SO : selectOptionsToSort){
            if(SO.getValue() <= pivotValue.getValue()){
                lessSelectOption.add(SO);
            }else if(SO.getValue() > pivotValue.getValue()){
                greaterSelectOption.add(SO);   
            }
        }
        list<selectOption> SortedSelectOptions = new list<selectOption>(); 
        SortedSelectOptions.addAll(selectOptionSortByValue(lessSelectOption));
        SortedSelectOptions.add(pivotValue);
        SortedSelectOptions.addAll(selectOptionSortByValue(greaterSelectOption));
        return SortedSelectOptions;
    }
}