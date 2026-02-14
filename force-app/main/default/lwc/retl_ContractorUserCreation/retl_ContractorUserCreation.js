import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import createPortalUser from '@salesforce/apex/RETL_ContractorUserCreation.createPortalUser';
import { NavigationMixin } from 'lightning/navigation';
import { CurrentPageReference } from 'lightning/navigation'
import getVerticalInfo from '@salesforce/apex/RETL_ContractorUserCreation.getVerticalInfo';
export default class Retl_ContractorUserCreation extends NavigationMixin(LightningElement) {
    @api recordId;
    showSpinner = false;

    @track creatingUser = false;
    @track updatingUser = false;
    @track noChange = false;

    @track contactData;
    verticalText;
    oldVerticalText;
    newVerticalText;
    @track selectedVerticals = [];
    @wire(getVerticalInfo, { contactId: '$recordId' })
    wiredInfo({ data, error }) {
        if (data) {
            this.contactData = data;
            this.verticalText = this.formatVerticalText(data.customerVerticals);

            this.selectedVerticals = this.parseVerticals(data.customerVerticals);

            if (!data.hasUser) {
                // SCENARIO: No portal user → show Create UI
                this.creatingUser = true;
                this.updatingUser = false;
                this.noChange = false;

            } else {
                // Portal user exists → compare old vs new
                let currentProfile = data.existingProfile;
                let oldVerticals = this.getVerticalsFromProfile(currentProfile, data.existingPermissions);
                this.oldVerticalText = oldVerticals.join(", ");
                this.newVerticalText = this.getNewOnly(oldVerticals, this.selectedVerticals);

                if (this.sameSet(oldVerticals, this.selectedVerticals)) {
                    // SCENARIO: No change needed
                    this.noChange = true;
                    this.creatingUser = false;
                    this.updatingUser = false;
                } else {
                    // SCENARIO: Need to update
                    this.updatingUser = true;
                    this.creatingUser = false;
                    this.noChange = false;
                }
            }
        }
    }
    getNewOnly(oldList, newList) {
        return newList.filter(v => !oldList.includes(v));
    }
    formatVerticalText(raw) {
        if (!raw) return "";

        // Split by comma or semicolon
        let list = raw.split(/[,;]+/)
            .map(v => v.trim())
            .filter(v => v);

        if (list.length === 1) {
            return list[0];                          // "Retail"
        }
        if (list.length === 2) {
            return `${list[0]} and ${list[1]}`;      // "Retail and District Management"
        }

        // For 3 or more (Retail, DM, Hospitality)
        let last = list.pop();
        return `${list.join(", ")} and ${last}`;
    }

    parseVerticals(raw) {
        return raw
            .split(/[,;]+/)
            .map(v => v.trim())
            .filter(v => v);
    }

    getVerticalsFromProfile(profileName, existingPermissions) {
        if (profileName.includes('DM') && existingPermissions?.includes('Retail_Contractor_Permission')) return ['District Management', 'Retail']; // DM always includes Retail
        if (profileName.includes('Retail') && existingPermissions?.includes('Retail_Contractor_Permission')) return ['Retail'];
        if (profileName.includes('DM') && !existingPermissions?.includes('Retail_Contractor_Permission')) return ['District Management'];
        return [];
    }

    sameSet(list1, list2) {
        return list1.length === list2.length &&
            list1.every(v => list2.includes(v));
    }

    handleSave() {
        this.showSpinner = true;
        createPortalUser({ contactId: this.recordId, duplicate: false, verticals: JSON.stringify(this.selectedVerticals) })
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
                } else if (errorMessage?.includes("Duplicate Username")) {
                    this.handleDuplicateUser();
                } else {
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
    handleDuplicateUser() {
        this.showSpinner = true;
        createPortalUser({ contactId: this.recordId, duplicate: true })
            .then(result => {
                this.showToast('Success', 'User created successfully', 'success', 'dismissable');
                this.dispatchEvent(new CloseActionScreenEvent());
            })
            .catch(error => {
                this.showSpinner = false;
                const errorMessage = JSON.stringify(error);
                if (errorMessage.includes("portal user already exists for contact")) {
                    this.showToast('error', 'Portal user already exists for this contact, Please contact system admin.', 'error');
                } else if (errorMessage?.includes("Duplicate Username")) {
                    this.showToast('error', 'The username is already in use in this or another Salesforce organization. Please contact your system administrator.', 'error');
                } else {
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