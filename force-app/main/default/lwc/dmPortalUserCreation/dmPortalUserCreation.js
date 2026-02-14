import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import createPortalUser from '@salesforce/apex/Dm_PortalUserCreation.createPortalUser';
import { NavigationMixin } from 'lightning/navigation';
import { CurrentPageReference } from 'lightning/navigation'

export default class DmPortalUserCreation extends NavigationMixin(LightningElement)  {
    @api recordId;
    showSpinner = false;

    handleSave() {
        this.showSpinner = true;
        createPortalUser({ contactId: this.recordId,duplicate:false })
            .then(result => {              
                this.showToast('Success', 'User created successfully', 'success', 'dismissable');
                this.dispatchEvent(new CloseActionScreenEvent());   
                this.refreshPage();            
            })
            .catch(error => {
                this.showSpinner = false;
                const errorMessage = JSON.stringify(error);              
                if (errorMessage.includes("portal user already exists for contact")) {
                    this.showToast('error', 'Portal user already exists for this contact, Please contact system admin.', 'error');
                }else if(errorMessage?.includes("Duplicate Username")){
                    this.handleDuplicateUser();
                }else{
                    this.showToast('error', 'User creation not allowed for this contact', 'error');
                }
                
                console.error('Error creating user: ', error);
            });
    }
    refreshPage() {
       
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,   
                objectApiName: 'Contact',  
                actionName: 'view'         
            }
        });
    }
    handleDuplicateUser(){
        this.showSpinner = true;
        createPortalUser({ contactId: this.recordId,duplicate:true })
            .then(result => {              
                this.showToast('Success', 'User created successfully', 'success', 'dismissable');
                this.dispatchEvent(new CloseActionScreenEvent());
            })
            .catch(error => {
                this.showSpinner = false;
                const errorMessage = JSON.stringify(error);              
                if (errorMessage.includes("portal user already exists for contact")) {
                    this.showToast('error', 'Portal user already exists for this contact, Please contact system admin.', 'error');
                }else if(errorMessage?.includes("Duplicate Username")){
                     this.showToast('error', 'The username is already in use in this or another Salesforce organization. Please contact your system administrator.', 'error');
                }else{
                    this.showToast('error', 'User creation not allowed for this contact', 'error');
                }
                
                console.error('Error creating user: ', error);
            });
    }
    closeScreen() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }
    showToast(title, message, variant, mode) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: mode
        });
        this.dispatchEvent(evt);
    }
}