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