import { LightningElement, wire, track } from "lwc";
import { getPicklistValues } from "lightning/uiObjectInfoApi";
import { getRecord } from 'lightning/uiRecordApi';
import getUserRoles from "@salesforce/apex/ManageUsersController.getUserRoles";
import updateAllocationGroupUser from "@salesforce/apex/ManageUsersController.updateAllocationGroupUser";
import removeAllocationGroupUser from "@salesforce/apex/ManageUsersController.removeAllocationGroupUser";
import CreateAllocationGroupUser from "@salesforce/apex/ManageUsersController.CreateAllocationGroupUser";
import getUsersQuery from "@salesforce/apex/UserService.getUsersQuery";
import prepareUserId from "@salesforce/apex/UserService.prepareUserId";
import getAllocationGroupUsersQuery from "@salesforce/apex/AllocationGroupUserService.getAllocationGroupUsersQuery";
import prepareAllocationGroupUserId from "@salesforce/apex/AllocationGroupUserService.prepareAllocationGroupUserId";
import getAllocationGroupQuery from "@salesforce/apex/AllocationGroupService.getAllocationGroupQuery";
import { CurrentPageReference, NavigationMixin  } from 'lightning/navigation';
import { deleteRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import lightningdatatableHideColumn from '@salesforce/resourceUrl/lightningdatatableHideColumn'
import {loadStyle} from 'lightning/platformResourceLoader'


const allocationGroupcolumns = [
    { label: 'Name', fieldName: 'UserName__c' },
    { label: 'Username', fieldName: 'UserUsername__c' },
    { label: 'Role', fieldName: 'UserRole__c' },
    { label: 'Email', fieldName: 'UserEmail__c' },
    { label: 'Start Date', fieldName: 'StartDate__c' },
    { label: 'End Date', fieldName: 'EndDate__c' },
    { label: '', fieldName: 'Id', initialWidth: 5, cellAttributes: { class:'column-id' /*important for reponsive */} }


];

const Userscolumns = [
    { label: 'Name', fieldName: 'Name' },
    { label: 'Username', fieldName: 'Username' },
    { label: 'Role', fieldName: 'RoleName__c' },
    { label: 'Email', fieldName: 'Email' },
    { label: 'Title', fieldName: 'Title' },
    { label: '', fieldName: 'Id', initialWidth: 5, cellAttributes: { class:'column-id' /*important for reponsive */} }
];

export default class ManageUsers extends NavigationMixin(LightningElement) {
    allocationGroupcolumns = allocationGroupcolumns;
    Userscolumns = Userscolumns;
    @track data;
    @track allocationGroupUsersData;
    @track updateUserModalAlertLabelValue = '';
    @track addUserModalAlertLabelValue = '';
    @track allocationGroupName = '';
    @track AddButtonVisibility = false;
    @track RemoveEditButtonVisibility = false;
    @track AddUserModal = false;
    @track UpdateUserModal = false;
    @track DeleteConfirmationModal = false;
    @track selectedDatatableAddRows = [];
    @track selectedDatatableRemoveRows = [];

    usersRolesPickListValues;
    currentPageReference = null; 
    urlStateParameters = null;
    agId;
    RowsTableDataAdd = [];
    RowsTableDataUpdate = [];
    allocationGroupStartDate;
    allocationGroupEndDate;
    UsersIds;


    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
       if (currentPageReference) {
          this.urlStateParameters = currentPageReference.state;
          console.log("this.urlStateParameters", currentPageReference);

          console.log("this.urlStateParameters", this.urlStateParameters);
          
            this.agId = this.urlStateParameters.c__agid || null;

       }
    }

    renderedCallback(){ 
        if(this.isCssLoaded) return
        this.isCssLoaded = true
        loadStyle(this, lightningdatatableHideColumn).then(()=>{
            console.log("Loaded Successfully");
        }).catch(error=>{ 
            console.error("Error in loading the css");
        })
    }

    navigateToAllocationGroupObjectHome() {
        console.log('Navigation');
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.agId,
                objectApiName: 'AllocationGroup__c',
                actionName: 'view'
                
            }
        });
    }

    async connectedCallback() {
        this.resetAll();
        this.getAllocationGroupData();
        let userRoles = [];
        const userRolesData = await getUserRoles() ;
        console.log(userRolesData);
        userRolesData.forEach(userRole => {
            userRoles.push({ label: userRole, value: userRole });
        });
        this.usersRolesPickListValues = userRoles;
    }

    async getAllocationGroupData(){
        const query = 'SELECT StartDate__c,EndDate__c,Name  FROM AllocationGroup__c WHERE Id  = \'' + this.agId +'\'';
        const allocationGroupDates = await getAllocationGroupQuery({query:query});
        this.allocationGroupName = '  Allocation Group Name: ' + allocationGroupDates[0].Name + ' ('+ allocationGroupDates[0].StartDate__c + ' - ' + allocationGroupDates[0].EndDate__c + ')';
        this.allocationGroupStartDate = allocationGroupDates[0].StartDate__c;
        this.allocationGroupEndDate = allocationGroupDates[0].EndDate__c;
    }

    handleKeyUp(event) {
        clearTimeout(this.typingTimer);
        let value = event.target.value;
        let name = event.target.name;

        this.typingTimer = setTimeout(() => {
            this[name] = value;
        }, this.doneTypingInterval);
    }

    handleChange(event) {
        this[event.target.name] = event.target.value;
        console.log("change", this[event.target.name]);
    }

   
    async handleRowActionAdd(event) {
        this.RowsTableDataAdd =[];

        let selectedAddRowsArray = [];
        const selectedRows = event.detail.selectedRows;

        if (selectedRows.length > 0) {
            this.AddButtonVisibility = true;
            }else{
            this.AddButtonVisibility = false;
        }

        for (let index = 0; index < selectedRows.length; index++) {
            this.RowsTableDataAdd.push(selectedRows[index].Id);
            selectedAddRowsArray = [...selectedAddRowsArray, selectedRows[index].Username]; 
        }
        this.selectedDatatableAddRows = selectedAddRowsArray;

        console.log('RowsTableDataAdd: ', this.RowsTableDataAdd);

    }

    async handleRowActionRemove(event) {
        this.RowsTableDataUpdate = [];
        let selectedRemoveRowsArray = [];

        const selectedRows = event.detail.selectedRows;
        

        if (selectedRows.length > 0) {
            this.RemoveEditButtonVisibility = true;
        }else{
            this.RemoveEditButtonVisibility = false;
        }

        for (let index = 0; index < selectedRows.length; index++) {
            this.RowsTableDataUpdate.push(selectedRows[index].Id);
            selectedRemoveRowsArray = [...selectedRemoveRowsArray, selectedRows[index].UserUsername__c]; 
        }


        if (selectedRows.length == 1) {
            this.allocationGroupEndDateField = selectedRows[0].EndDate__c;
            this.allocationGroupStartDateField = selectedRows[0].StartDate__c;
        }else{
            this.allocationGroupEndDateField = '';
            this.allocationGroupStartDateField = '';
        }
        this.selectedDatatableRemoveRows = selectedRemoveRowsArray;

    }

    handleAddUserModal(event){
        this.AddUserModal = true;
    }

    handleUpdateUserModal(event){
        this.UpdateUserModal = true;
    }

    handleDeleteConfirmationModal(event){
        this.DeleteConfirmationModal = true;
    }

    closeModal() {
        this.AddUserModal = false;
        this.UpdateUserModal = false;
        this.DeleteConfirmationModal = false;  
        this.updateUserModalAlertLabelValue = '';
        this.addUserModalAlertLabelValue = '';
    }

    async addUsersubmitDetails(event){

        if(this.addUserStartDateField>this.addUserEndDateField)    
        {
            this.addUserModalAlertLabelValue = 'Please select the start date to be before the end date.';
        }else if(this.addUserStartDateField<this.allocationGroupStartDate)
        {
            this.addUserModalAlertLabelValue = 'Please select the start date to be in between Allocation Group start and end dates.';
        }else if(this.addUserEndDateField>this.allocationGroupEndDate)
        {
            this.addUserModalAlertLabelValue = 'Please select the end date to be in between Allocation Group start and end dates.';
        }else{
            this.addUserModalAlertLabelValue = '';
            
            try{
                await CreateAllocationGroupUser({idList:this.RowsTableDataAdd, StartDate: this.addUserStartDateField ,EndDate: this.addUserEndDateField,allocationGroupId: this.agId})
            
                const evt = new ShowToastEvent({
                    title: 'Add Users to Allocation Group ',
                    message: 'Users have been added successfully ',
                    variant: 'success',
                });
                this.dispatchEvent(evt);
            }
            catch(e){
                const evt = new ShowToastEvent({
                    title: 'Add Users to Allocation Group  ',
                    message: 'Adding users to allocation group failed ' + JSON.stringify(e),
                    variant: 'error',
                });
                this.dispatchEvent(evt);
            }
            
            this.resetAll();
            this.closeModal();
        }
    }

    async submitDetails(event){

        if(this.allocationGroupStartDateField>this.allocationGroupEndDateField)    
        {
            this.updateUserModalAlertLabelValue = 'Please select the start date to be before the end date.';
        }else if(this.allocationGroupStartDateField<this.allocationGroupStartDate){
            this.updateUserModalAlertLabelValue = ' Please select the start date to be in between Allocation Group start and end dates.';
        }else if(this.allocationGroupEndDateField>this.allocationGroupEndDate){
            this.updateUserModalAlertLabelValue = ' Please select the end date to be in between Allocation Group start and end dates.';
        }else{
            this.updateUserModalAlertLabelValue = '';
            console.log(this.allocationGroupStartDateField );
            console.log(this.allocationGroupEndDateField );

            try{
                await updateAllocationGroupUser({idList:this.RowsTableDataUpdate, startDate: this.allocationGroupStartDateField ,endDate: this.allocationGroupEndDateField});
            
                const evt = new ShowToastEvent({
                    title: 'Update Users Start and End Dates ',
                    message: 'Start and end dates updated successfully ',
                    variant: 'success',
                });
                this.dispatchEvent(evt);
            }
            catch(e){
                const evt = new ShowToastEvent({
                    title: 'Update Users Start and End Dates ',
                    message: 'Start and end dates update failed ' + JSON.stringify(e),
                    variant: 'error',
                });
                this.dispatchEvent(evt);
            }


            

            this.resetAll();
            this.closeModal();
        }

    }

    async handleRemoveUserToAllocationGroup(event){
        try{
            await removeAllocationGroupUser({usersList:this.RowsTableDataUpdate})
        
            const evt = new ShowToastEvent({
                title: 'Remove Users from Allocation Group ',
                message: 'Users have been removed successfully ',
                variant: 'success',
            });
            this.dispatchEvent(evt);
        }
        catch(e){
            const evt = new ShowToastEvent({
                title: 'Remove Users from Allocation Group ',
                message: 'Removing users from allocation group failed ' + JSON.stringify(e),
                variant: 'error',
            });
            this.dispatchEvent(evt);
        }
        this.closeModal();
        this.resetAll();
    }

    async handleSearchAll(event) {
        let newTableData = [];

        console.log(this.userRoleField);
        console.log(this.userNameField);
        console.log(this.userEmailField);
        console.log(this.userTitleField);  
        
      var condition = (this.userRoleField !== '' && this.userRoleField !== null && this.userRoleField !== undefined
          ? 'RoleName__c LIKE \'' +
          '%' +
          this.userRoleField +
          '%\''
        : 'RoleName__c LIKE \'%Sales Manager%\'');

          condition += (this.userNameField !== '' && this.userNameField !== null && this.userNameField !== undefined
          ? (condition !== '' && condition !== null ? ' AND ' : '') +
            ' Name LIKE \'' +
            '%' +
            this.userNameField +
            '%\''
          : '');

          condition += (this.userTitleField !== '' && this.userTitleField !== null && this.userTitleField  !== undefined
          ? (condition !== '' && condition !== null ? ' AND ' : '') +
            ' Title  LIKE \'' +
            '%' +
            this.userTitleField +
            '%\''
          : '');

          condition += (this.userEmailField !== '' && this.userEmailField !== null && this.userEmailField !== undefined
          ? (condition !== '' && condition !== null ? ' AND ' : '') +
            ' Email LIKE \'' +
            '%' +
            this.userEmailField +
            '%\''
          : '');

          var query;

          if (this.UsersIds == '' || this.UsersIds == null || this.UsersIds == undefined ) {
            query = 'SELECT Id,Name,RoleName__c,Email,Title,Username FROM User WHERE ' + condition;
           }else{
           query = 'SELECT Id,Name,RoleName__c,Email,Title,Username FROM User WHERE ' + condition + ' AND Id NOT IN ('+ this.UsersIds +')' ;
           }
          console.log(query);

        const newData = await getUsersQuery({query:query});
        console.log(newData);
        newData.forEach(record => record.linkName = '/'+record.Id);
            for (let i = 0; i < newData.length; i++) {
            newTableData.push(newData[i]);
        }
        console.log(newTableData);

        this.data = newTableData;
    }

    async resetAll() {
        console.log('resetall');

        this.UsersIds= '';
        this.userRoleField= '';
        this.userNameField= '';
        this.userEmailField= '';
        this.userTitleField= '';
        this.AddButtonVisibility = false;
        this.RemoveEditButtonVisibility = false;
        this.selectedDatatableAddRows = [];
        this.selectedDatatableRemoveRows = [];

        let newTableData1 = [];
        const query1 = 'SELECT Id,User__c,UserName__c,UserEmail__c,UserRole__c,StartDate__c,EndDate__c,UserUsername__c  FROM AllocationGroupUser__c WHERE AllocationGroup__c  = \'' + this.agId +'\' AND (IsActive__c = true OR StartDate__c > TODAY)';
        console.log(query1);
        const newAllocationGroupUsersData = await getAllocationGroupUsersQuery({query:query1});
        console.log(newAllocationGroupUsersData);

            for (let i = 0; i < newAllocationGroupUsersData.length; i++) {
            newTableData1.push(newAllocationGroupUsersData[i]);
            this.UsersIds += '\'' + newAllocationGroupUsersData[i].User__c + '\',';
            }
        this.UsersIds= this.UsersIds.slice(0, -1);
        this.allocationGroupUsersData = newTableData1;

        let newTableData = [];
        let query;
        console.log('UsersIds');
        console.log(this.UsersIds );

        if (this.UsersIds == '' || this.UsersIds == null || this.UsersIds == undefined ) {
            query = 'SELECT Id,Name,RoleName__c,Email,Title,Username FROM User WHERE  RoleName__c LIKE \'%Sales Manager%\' LIMIT 200';
        }else{
            query = 'SELECT Id,Name,RoleName__c,Email,Title,Username FROM User WHERE  RoleName__c LIKE \'%Sales Manager%\' AND Id NOT IN ('+ this.UsersIds +') LIMIT 200';
        }

        const newData = await getUsersQuery({query:query});
        for (let i = 0; i < newData.length; i++) {
            newTableData.push(newData[i]);
                }
        this.data = newTableData;
        
        const lwcComboboxFields = this.template.querySelectorAll(
            'lightning-combobox'
        );
        if (lwcComboboxFields) {
            lwcComboboxFields.forEach(field => {
                field.value = '';
            });
        }

        const lwcInputFields = this.template.querySelectorAll(
            'lightning-input'
        );
        if (lwcInputFields) {
            lwcInputFields.forEach(field => {
                field.value = '';
            });
        }
    }
}