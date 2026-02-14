import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecordNotifyChange } from 'lightning/uiRecordApi';

// Apex Method Imports
import createAccount from '@salesforce/apex/RETL_AccountCreation.createAccount';

export default class RetailCreateAccount extends LightningElement {
    // -----------------------------------------------------------------
    // 1. PUBLIC PROPERTIES (API)
    // -----------------------------------------------------------------
    @api recordId; // ID of the Lead record passed to the component
    @api newAccountId; // Output variable for the created Account ID (no longer used for flow navigation, but kept if other systems rely on it)
    @api availableActions = []; // Kept but no longer used for Flow navigation

    // -----------------------------------------------------------------
    // 2. PRIVATE TRACKED PROPERTIES (STATE)
    // -----------------------------------------------------------------
    @track selectedType = '';
    @track accountName = '';
    @track uaeVATRegisterNumber = ''; 
    @track taxAuthority = ''; // Tax Authority field
    
    // State variable to control creation mode visibility
    @track showCreationOptions = false; 

    // UI State
    isLoading = false;

    // -----------------------------------------------------------------
    // 3. GETTERS (COMPUTED PROPERTIES)
    // -----------------------------------------------------------------
    get options() {
        return [
            { label: 'Brand', value: 'Brand' },
            { label: 'Group', value: 'Group' }
        ];
    }

    get showNameInput() {
        return this.showCreationOptions && this.selectedType !== '';
    }

    get showSaveButton() {
        return this.showCreationOptions && this.selectedType;
    }

    get showRegistrationToggle() {
        return true;
    }

    // -----------------------------------------------------------------
    // 4. LIFECYCLE HOOKS
    // -----------------------------------------------------------------
    connectedCallback() {
        // Initialization logic, if any
    }
    
    // -----------------------------------------------------------------
    // 5. EVENT HANDLERS
    // -----------------------------------------------------------------
    
    /**
     * Handles the toggle state for showing the creation options.
     * Resets form fields when the toggle is switched off.
     * @param {Event} event - The toggle change event.
     */
    handleRegisterToggle(event) {
        this.showCreationOptions = event.target.checked;
        
        if (!this.showCreationOptions) {
            this.resetForm(); 
        }
    }

    handleSelectionChange(event) {
        this.selectedType = event.detail.value;
    }

    handleNameChange(event) {
        this.accountName = event.target.value;
    }
    
    handleVATChange(event) {
        this.uaeVATRegisterNumber = event.target.value;
    }

    handleTaxAuthorityChange(event) {
        this.taxAuthority = event.target.value;
    }

    // -----------------------------------------------------------------
    // 6. BUSINESS LOGIC METHODS
    // -----------------------------------------------------------------

    /**
     * @description Resets all form fields and state variables to their initial state.
     */
    resetForm() {
        this.selectedType = '';
        this.accountName = '';
        this.uaeVATRegisterNumber = '';
        this.taxAuthority = '';
        this.showCreationOptions = false; 
    }

    /**
     * @description Validates input and calls the Apex method to create the new account.
     * Triggers record refresh and form reset on success.
     */
    async handleSave() {
        // --- Validation Logic ---
        if (!this.showCreationOptions) {
            this.showToast('Error', 'Please enable the registration toggle to create a new Brand or Group.', 'error');
            return;
        }

        if (!this.selectedType) {
            this.showToast('Error', 'Please select Brand or Group to create.', 'error');
            return;
        }
        if (!this.accountName?.trim()) {
            this.showToast('Error', 'Please enter a name for the new record.', 'error');
            return;
        }
        
        const saveType = this.selectedType; // 'Brand' or 'Group'
        const saveName = this.accountName;

        // --- Apex Call ---
        this.isLoading = true;
        try {
            const record = await createAccount({
                name: saveName,
                type: saveType,
                leadId: this.recordId,
                brandId: null, // Always null in this simplified creation mode
                groupId: null, // Always null in this simplified creation mode
                salesCategory: null,
                uaeVATRegisterNumber: this.uaeVATRegisterNumber,
                taxAuthority: this.taxAuthority 
            });

            this.showToast('Success', `${saveType} created successfully!`, 'success');
            
            this.newAccountId = record.Id; 
            
            // 1. Refresh the Lead Record Detail page (LDS refresh)
            if (this.recordId) {
                await getRecordNotifyChange([{ recordId: this.recordId }]);
                console.log('Lead record details refreshed.');
            }

            // 2. Reset the Form
            this.resetForm();
            
        } catch (error) {
            console.error(error);
            this.showToast('Error', error.body?.message || error.message || 'An unknown error occurred.', 'error');
        } finally {
            this.isLoading = false;
        }
    }

    /**
     * @description Fires a standard toast message.
     * @param {string} title - The title of the toast.
     * @param {string} message - The message body.
     * @param {string} variant - The type of toast ('success', 'error', 'warning', 'info').
     */
    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}