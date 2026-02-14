import { LightningElement, api, track, wire } from 'lwc';
import syncOpportunityToYardi from '@salesforce/apex/RETL_LeadSyncController.syncOpportunityToYardi'; 
import getYardiRelatedInfo from '@salesforce/apex/RETL_LeadSyncController.getYardiRelatedInfo'; 
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecordNotifyChange } from 'lightning/uiRecordApi';
import { NavigationMixin } from 'lightning/navigation';
import pushLCApprovalToYardi from '@salesforce/apex/RETL_LeadSyncController.pushLCApprovalToYardi';
import updateOpportunityStageAndReason from '@salesforce/apex/RETL_LeadSyncController.updateOpportunityStageAndReason';
import syncProposalToYardi from '@salesforce/apex/RETL_LeadSyncController.syncProposalToYardi';


export default class SyncLeadButton extends NavigationMixin(LightningElement) {
    @api recordId;
    @track isLoading = true; // Start true to show spinner immediately
    @track yardiData = {}; 

    @track isModalOpen = false;
    @track selectedCancelOption;
    @track selectedReason;
    @track comments = '';

    // Full list of codes used for mapping and display order
    YARDI_CODE_ORDER = [
        { key: 'BrandYardiId', label: 'Brand Code' },
        { key: 'AccountYardiId', label: 'Customer Code' },
        { key: 'GroupYardiId', label: 'Group Code' },
        { key: 'ContactYardiId', label: 'Contact Code' },
        { key: 'ContactRoleYardiId', label: 'Contact Role Code' },
        { key: 'ContentVersionYardiId', label: 'Brand Profile File Code' },
        { key: 'OpportunityYardiId', label: 'Lead Code', isPrimaryAction: true }
    ];

    // Initialize syncStatus with safe default values to prevent "undefined" errors
    @track syncStatus = this.YARDI_CODE_ORDER.reduce((acc, item) => {
        // Using the key property (e.g., 'BrandYardiId') as the map key
        acc[item.key] = { label: item.label, displayValue: 'Loading...', iconName: 'utility:refresh', variant: 'default', badgeClass: '' };
        return acc;
    }, {});


    // --- Data Fetching and Mapping ---

    @wire(getYardiRelatedInfo, { opportunityId: '$recordId' })
    wiredYardiInfo({ data, error }) {
        this.isLoading = false; 

        if (data) {
            this.yardiData = data;
            this.mapDataToSyncStatus(); 
        } else if (error) {
            console.error('Error fetching Yardi info:', error);
            this.showToast('Error', 'Failed to retrieve sync status.', 'error');
        }
    }

    /**
     * Maps the flat Apex data (yardiData) into the structured syncStatus object.
     */
    mapDataToSyncStatus() {
        if (!this.yardiData) return;
        
        // Helper function for status configuration
        const getStatusConfig = (value) => {
            const isComplete = !!value;
            const displayValue = value || 'Pending';
            
            let iconName = 'utility:info';
            let variant = 'default';
            let badgeClass = 'slds-badge_lightest slds-theme_info';

            if (isComplete) {
                iconName = 'utility:success';
                variant = 'success';
                badgeClass = 'slds-badge_lightest slds-theme_success';
            } else if (!isComplete && this.isPushDisabledLogic) {
                // Highlight codes that are prerequisites but missing
                iconName = 'utility:error';
                variant = 'error';
                badgeClass = 'slds-badge_lightest slds-theme_error';
            }
            
            return {
                isComplete,
                displayValue,
                iconName,
                variant,
                badgeClass
            };
        };
        
        // Map ALL 7 codes from the Apex response
        this.YARDI_CODE_ORDER.forEach(item => {
            const value = this.yardiData[item.key];
            this.syncStatus[item.key] = {
                label: item.label,
                ...getStatusConfig(value)
            };
        });
    }

    // --- Computed Properties for UI Logic ---

    // Core logic: Disabled if Brand or Customer missing OR Lead Code exists
    get isPushDisabledLogic() {
        if (!this.yardiData) return true;
        
        return !this.yardiData.BrandYardiId || 
               !this.yardiData.AccountYardiId || 
               !!this.yardiData.OpportunityYardiId; 
    }

    // Final property used in the template (combines logic and loading state)
    get isPushDisabled() {
        if (this.isLoading) {
            return true;
        }

        // The button is ENABLED if (isCoreLogicMet AND areLineItemsPresent) is true.
        // It is DISABLED if the entire condition is FALSE.
        return !(this.isCoreLogicMet && this.areLineItemsPresent);
    }
    
    // --- Event Handlers ---

    async handleSync() {
        this.isLoading = true;
        try {
            const result = await syncOpportunityToYardi({ opportunityId: this.recordId });
            this.showToast('Success', result, 'success');
            getRecordNotifyChange([{ recordId: this.recordId }]);
        } catch (error) {
            console.error(error);
            this.showToast('Error', error.body?.message || 'Yardi callout failed.', 'error');
        } finally {
             // Let the wire service fetch the new data, then clear the spinner
             setTimeout(() => {
                 this.isLoading = false;
            }, 500); 
        }
    }

    handleViewLog(event) {
         event.preventDefault(); 
         this[NavigationMixin.Navigate]({
             type: 'standard__objectPage',
             attributes: {
                 objectApiName: 'Sync_Log__c',
                 actionName: 'home',
             },
         });
    }

    // --- Utility ---

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    /**
     * Checks if the two primary pre-conditions are met for sync initiation.
     * Must be Approved AND Lead Code must be Null/Pending.
     * @returns {Boolean} true if the core business logic allows pushing.
     */
    get isCoreLogicMet() {
        if (!this.yardiData) return false;

        const preApprovalStatus = this.yardiData.PreApprovalStatus;
        const leadCode = this.yardiData.OpportunityYardiId;

        // Condition 1: RETL_AM_PreApproval__c must be 'Approved'
        const isApproved = (preApprovalStatus === 'Approved' || preApprovalStatus === 'Not Required');

        // Condition 2: Lead Code (OpportunityYardiId) must be null/empty
        const isYardiCodeNull = !leadCode;

        // ENABLED only if BOTH are TRUE
        return isApproved && isYardiCodeNull;
    }

    /**
     * Checks if Opportunity Line Items are present.
     * @returns {Boolean} true if line items exist (count > 0).
     */
    get areLineItemsPresent() {
        // Note: The Apex sends 'OpportunityLineItemCount' as a string.
        if (!this.yardiData || !this.yardiData.OpportunityLineItemCount) return false;
        
        // Convert the string count back to an integer for comparison
        return parseInt(this.yardiData.OpportunityLineItemCount, 10) > 0;
    }

    get isLcApprovalDisabled() {
        const stage = this.yardiData?.OpportunityStage;
        return !(stage === 'LC Approved' || stage === 'LC Rejected');
    }


    async handleLcApproval() {
        this.isLoading = true;
        try {
            await pushLCApprovalToYardi({ opportunityId: this.recordId });
            this.showToast('Success', 'LC Approval pushed to Yardi.', 'success');
        } catch (error) {
            this.showToast('Error', error.body?.message || 'LC Approval push failed.', 'error');
        } finally {
            this.isLoading = false;
        }
    }

    // Cancel start
    get showCancelDetails() {
        return this.selectedCancelOption !== undefined;
    }

    get isSubmitDisabled() {
        return !(this.selectedCancelOption && this.selectedReason && this.comments);
    }

    cancelOptions = [
        { label: 'Cancel Proposal', value: 'Cancel' },
        { label: 'Clone Opportunity and Cancel Proposal', value: 'CloneAndCancel' }
    ];

    cancelReasons = [
        { label: 'Lost - Availability', value: 'Lost - Availability' },
        { label: 'Lost - Price', value: 'Lost - Price' },
        { label: 'Lost - Unit Change', value: 'Lost - Unit Change' }
    ];

    // Open modal
    openModal() {
        this.isModalOpen = true;
    }

    // Close modal
    closeModal() {
        this.isModalOpen = false;
        this.selectedCancelOption = undefined;
        this.selectedReason = undefined;
        this.comments = '';
    }

    // Handle radio button change
    handleOptionChange(event) {
        this.selectedCancelOption = event.detail.value;
    }

    // Handle combobox change
    handleReasonChange(event) {
        this.selectedReason = event.detail.value;
    }

    // Handle comments input
    handleCommentsChange(event) {
        this.comments = event.target.value;
    }

    // Submit modal
    async handleSubmit() {
        this.isLoading = true;

        try {
            const clonedOppId = await updateOpportunityStageAndReason({
                oppId: this.recordId,
                stageName: 'Closed Lost',
                lossReason: this.selectedReason,
                comments: this.comments,
                actionType: this.selectedCancelOption
            });

            if (clonedOppId) {
                this.showToast('Success', 'Record cloned successfully.', 'success');

                this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: clonedOppId,
                        actionName: 'view'
                    }
                });
            } else {
                this.showToast('Updated', 'Proposal cancelled successfully.', 'success');
                this.closeModal();
            }

        } catch (error) {
            this.showToast(
                'Error',
                error.body?.message || error.message || 'Unknown error',
                'error'
            );
            console.error(JSON.stringify(error));
        } finally {
            this.isLoading = false;
        }
    }

    //cancel end

    isEditModalOpen = false;

    openEditModal() {
        this.isEditModalOpen = true;
    }

    closeEditModal() {
        this.isEditModalOpen = false;
    }


    // user to click Sync Edited Proposal
    async syncEditedProposal() {       

            this.isLoading = true;
            try {
                // 3️ Call Apex method to update OPP + OLI
                await syncProposalToYardi({
                    oppId: this.recordId
                });
                window.location.reload();
                
            } catch (error) {
                this.showToast('Error', error.body?.message || 'Failed to Sync proposal', 'error');
            } finally {
                this.isLoading = false;
            }
    }


    // ------------------ BUTTON VISIBILITY LOGIC ------------------

        get showEditProposal() {
            return (
                this.yardiData?.OpportunityStage === 'Submitted for Proposal' &&
                this.yardiData?.TenantCode &&
                this.yardiData?.ProposalYardiId                 
            );
        }

        get showSyncProposal() {
            return (
                this.yardiData?.OpportunityStage === 'AM Approved' &&
                this.yardiData?.TenantCode &&
                this.yardiData?.ProposalYardiId
            );
        }

       get showCancelProposal() {
        const blockedStages = ['Closed Won', 'Closed Lost', 'LC Approved'];
        return (
            !blockedStages.includes(this.yardiData?.OpportunityStage) &&
            this.yardiData?.TenantCode &&
            this.yardiData?.ProposalYardiId
        );
    }

    get showLCApproval() {
        return (
            // this.yardiData?.OpportunityStage === 'Awaiting LC Approval' && ( this.yardiData.LcApprovalStatus === 'LC Approved' || this.yardiData.LcApprovalStatus === 'LC Rejected' ) &&
            (this.yardiData?.OpportunityStage === 'Awaiting LC Approval' || this.yardiData?.OpportunityStage === 'LC Approved' || this.yardiData?.OpportunityStage === 'LC Rejected') && 
            ( this.yardiData?.LcApprovalStatus === 'Approved' || this.yardiData?.LcApprovalStatus === 'Rejected' ) &&
            this.yardiData?.TenantCode &&
            this.yardiData?.ProposalYardiId
        );
    }

}