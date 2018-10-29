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

        list<SelectOption> listSO = new list<SelectOption>();
        listSO.add(new SelectOption('', ''));

        for (Account account : [
            select Name, Id from Account where C501_Merge_Targets__c > 0 order by Name asc
            limit 999]) {

                for (C501_Account_Merge__c mergeAccount : [
                    select Account__c from C501_Account_Merge__c
                    where Account__c = :account.Id
                        and Merge_Target_Account__c <> :account.Id
                        and Merge_Confidence__c >= :fromMergeConfidence
                        and Merge_Confidence__c <= :toMergeConfidence
                        and Merge_Action__c <> 'Ignore' 
                    limit 1]) {
                        if (String.isBlank(programName)) {
                            listSO.add(new SelectOption(account.Id, account.Name));
                        }
                        else {
                            for (C501_Service_Household__c serviceHousehold : [
                                select C501_Household__c from C501_Service_Household__c
                                where C501_Household__c = :account.Id and C501_Program__c = :programName
                                limit 1]) {
                                    listSO.add(new SelectOption(account.Id, account.Name));
                                }
                        }
                    }
            }

        return listSO;
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
}