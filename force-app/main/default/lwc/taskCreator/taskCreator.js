import { LightningElement, track } from 'lwc';
import insertTaskMethod from '@salesforce/apex/insertTaskClass.insertTaskMethod';
import getColumnNames from '@salesforce/apex/insertTaskClass.getColumnNames';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class taskCreator extends LightningElement {
    @track reportName;
    @track fieldName;
    @track subject;
    @track priority;
	@track dueDate;
    @track assignto;
    @track SelectUser;
    @track SelectGroup;
    @track SelectQueue;
    @track actionitem = 'Create Tasks';
    @track message;
    @track isError = false;
    @track isSuccess = false;
    @track showSpinner = false;
    @track Group = false;
    @track Queue = false;
    @track User = false;
    @track isTaskSelected = true;
    @track filedOptions = [];

    priorityOptions = [
        { label: 'High', value: 'High' },
        { label: 'Normal', value: 'Normal' },
        { label: 'Low', value: 'Low' },
    ];
  
    actionitemOptions = [
        { label: 'Create Tasks', value: 'Create Tasks' },
        { label: 'Change Owner', value: 'Change Owner' },
    ];

    assignOptions = [
        { label: 'Group', value: 'Group' },
        { label: 'Queue', value: 'Queue' },
        { label: 'User', value: 'User' },
    ]

    Groupfilter = {
        criteria: [
            {
                fieldPath: 'Type',
                operator: 'eq',
                value: 'Group',
            },
        ]
    }

    Queuefilter = {
        criteria: [
            {
                fieldPath: 'Type',
                operator: 'eq',
                value: 'Queue',
            },
        ]
    }

    handleInputChange(event) {
        const fieldName = event.target.dataset.field;
        if (fieldName) {
            this[fieldName] = event.target.value;
        }
    }
    handleReportNameChange(event) {
        this.reportName =  event.target.value;
          
          getColumnNames({ 
            ReportNme: this.reportName 
        })
        .then(result => {
            if (result.message === 'Report not found') {
                this.message = result.message;
                this.isError = true;
                this.isSuccess = false;
                this.dispatchEvent( 
                    new ShowToastEvent({
                    title: 'Error',
                    message: 'Oops Report not found !',
                    variant: 'error',
                    mode: 'dismissable',
                })
             );
                this.showSpinner = false;
            }   else {
                console.log('columnMap------'+JSON.stringify(result.columnMap));
                this.filedOptions = [];
                for (var key in result.columnMap) {
                    this.filedOptions.push({ label: key, value: result.columnMap[key] });
                    console.log('key', key, result.columnMap[key]);
                }
                console.log('filedOptions------'+JSON.stringify(this.filedOptions));
                
            }
        });
          
    }

    handlePriorityChange(event) {
        this.priority = event.detail.value;
    }

    handledueDateChange (event) {
        this.dueDate = event.detail.value;
    }
	
    handlefieldNameChange(event) {
        this.fieldName = event.detail.value;
    }

    handleActionItemChange(event) {
        this.actionitem = event.detail.value;
        
        if(this.actionitem == 'Create Tasks'){
            this.isTaskSelected = true;  
        } else {
            this.isTaskSelected = false; 
        }
    }

    handleAssignChange(event) {
        this.assignto = event.detail.value;
        if(this.assignto == 'Group'){
        this.Group = true;
        this.Queue = false;
        this.User = false;
        }
        if (this.assignto == 'Queue'){
        this.Queue = true;
        this.Group = false;
        this.User = false;
        }
        if (this.assignto == 'User'){
        this.User = true;
        this.Group = false;
        this.Queue = false;
        }
    }

    handleUserChange(event){
        this.SelectUser = event.detail.recordId
        console.log('this.SelectUser-------'+this.SelectUser);
    }

    handleGroupChange(event){
        this.SelectGroup = event.detail.recordId;
        console.log('this.SelectGroup------'+this.SelectGroup);
    }

    handleQueueChange(event){
        this.SelectQueue = event.detail.recordId;
        console.log('this.SelectQueue------'+this.SelectQueue);
    }

    insertTask() {
        this.showSpinner = true;
        if(this.actionitem == 'Create Tasks'){
            if (!this.reportName || !this.fieldName || !this.subject || !this.priority || !this.actionitem || !this.dueDate) {
                this.message = 'Please fill in all fields.';
                this.isError = true;
                this.isSuccess = false;
                const toastEvent = new ShowToastEvent({
                    title: 'warning',
                    message: 'Please fill  all required fields.',
                    variant: 'warning',
                    mode: 'dismissable',
                });
                this.dispatchEvent(toastEvent);
                this.showSpinner = false;
                return;
            }
        }

        insertTaskMethod({ 
            fieldName: this.fieldName, 
            ReportNme: this.reportName, 
            sub: this.subject, 
            UserId: (this.SelectUser || this.SelectGroup || this.SelectQueue), 
            prty: this.priority,
			duedate: this.dueDate,
            actionitem : this.actionitem
        })
        .then(result => {
            if (result === 'Report not found') {
                this.message = 'Report not found';
                this.isError = true;
                this.isSuccess = false;
                this.dispatchEvent( 
                    new ShowToastEvent({
                    title: 'Error',
                    message: 'Oops Report not found !',
                    variant: 'error',
                    mode: 'dismissable',
                })
             );
                this.showSpinner = false;
            } else if (result === 'Task is successfully created') {
                this.message = result;
                this.isError = false;
                this.isSuccess = true;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: this.message,
                        variant: 'success',
                    })
                );
                this.showSpinner = false;
                this.fieldName ='';
                this.reportName = '';
                this.subject = '';
                this.SelectGroup = '';
                this.SelectQueue = '';
                this.SelectUser = '';
                this.User = false;
                this.Group = false;
                this.Queue = false;
                this.priority  = '';
				this.dueDate = '';
                this.assignto = '';
            } else if(result === 'Owner is successfully updated'){
                this.message = result;
                this.isError = false;
                this.isSuccess = true;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: this.message,
                        variant: 'success',
                    })
                );
                this.showSpinner = false;
                this.showSpinner = false;
                this.fieldName ='';
                this.reportName = '';
                this.subject = '';
                this.SelectGroup = '';
                this.SelectQueue = '';
                this.SelectUser = '';
                this.User = false;
                this.Group = false;
                this.Queue = false;
                this.priority  = '';
				this.dueDate = '';
                this.assignto = '';
            } else {
                this.message = result;
                this.isError = true;
                this.isSuccess = false;
                this.showSpinner = false;
                this.dispatchEvent( 
                    new ShowToastEvent({
                    title: 'Error',
                    message: this.message,
                    variant: 'error',
                    mode: 'dismissable',
                })
              );
            }
        })
        .catch(error => {
             if(error.body.message =='List index out of bounds: -1'){
                this.message = 'Please enter the correct field name using all capital letters and replace any empty spaces with an' + ' _ '+ 'underscore.'
                this.isError = true;
                this.isSuccess = false;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: this.message,
                        variant: 'error',
                    })
                );
                this.showSpinner = false;
            } else {
            this.message = 'Error: ' + (error.body.message);
            this.isError = true;
            this.isSuccess = false;
            this.showSpinner = false;
            this.dispatchEvent( 
                new ShowToastEvent({
                title: 'Error',
                message: this.message,
                variant: 'error',
                mode: 'dismissable',
            })
          );
         }
        });
    }
}