/// This module defines a minimal Coin and Balance.
module NamedAddr::DTCard {

    use Std::Signer;
    /// Address of the admin
    const ADMIN_ACCOUNT: address = @NamedAddr;

    /// Error codes
    const ENOT_ADMIN_ACCOUNT: u64 = 0;  
    const EALREADY_HAS_DTCARD: u64 = 1;
    const EDTCARD_NOT_SIGNUP: u64 = 2;
    const EALREADY_ISSUED: u64 = 3;
    const EDTCARD_NOT_EXIST: u64 = 4;
    const EDTCARD_NOT_VALID: u64 = 5;
    const EDTCARD_EXPIRED: u64 = 6;

    struct DTCard has key, store, drop {
        student_id: u64,
        expiry_date: u64,
        issued: bool
    }

    struct Store has key, store{
        dtcard: DTCard
    }


    public fun dtcard_signup(account: &signer, id: u64) {
        // abort if the sender student already has Store
        assert!(!exists<Store>(Signer::address_of(account)), EALREADY_HAS_DTCARD);

        let empty_dtcard = DTCard { student_id: id, expiry_date: 0, issued: false };
        let dtcard_holder = Store { dtcard: empty_dtcard };

        move_to<Store>(account, dtcard_holder)
    }

    public fun issue_DTCard(admin: &signer, student_address:address) acquires Store {
        
        assert!(Signer::address_of(admin) == ADMIN_ACCOUNT, ENOT_ADMIN_ACCOUNT);
        assert!(exists<Store>(student_address), EDTCARD_NOT_SIGNUP);

        let dtcard_ref = &mut borrow_global_mut<Store>(student_address).dtcard;

        assert!(dtcard_ref.issued==false, EALREADY_ISSUED);
    
        dtcard_ref.issued = true;
        dtcard_ref.expiry_date = 1713240000;

    }

    public fun validate_dtcard(addr: address) acquires Store {
        // Abort if the resources(store)does not exist under addr
        assert!(exists<Store>(addr), EDTCARD_NOT_EXIST);

        let student_card = &borrow_global<Store>(addr).dtcard;
        // Abort if the tcard exists but is not issued
        assert!(student_card.issued == true, EDTCARD_NOT_VALID);
    } 

    #[test(account = @NamedAddr)]
    fun happy_admin(account: &signer) acquires Store{
        let addr = Signer::address_of(account);
        dtcard_signup(account, 12);
        issue_DTCard(account, addr);
        validate_dtcard(addr);
    }
    
    // Admin tries to issue DTCard but the student did not sign
    // up (resource is not initialized) 
    #[test(account= @NamedAddr)]
    #[expected_failure(abort_code = 2)]
    fun not_initialized(account: &signer) acquires Store{
        issue_DTCard(account, Signer::address_of(account))
    }

    //non-admin tries to issue DTCard 
    // This test provides a testing for managing to issue DTCard as an admin
    //  while using the address of non-admin
    #[test(account=@0xC)]
    #[expected_failure(abort_code = 0)]
    fun no_access (account:&signer) acquires Store{
        issue_DTCard(account, Signer::address_of(account));
    }

    // A student is happy(test passed when) DT card is issued to a student after signup
    // #[test(account=@0xC)]
    // fun happy_student( ) {
    //     let 
    // }

    // Test where it should abort when trying to authenticate an invalid DTCard
    #[test(account=@0xCDD)]
    #[expected_failure(abort_code = 4)]
    fun invalid_tcard(account: &signer) acquires Store{
        validate_dtcard(Signer::address_of(account));
    }

    #[test(account = @0xCAD)]
    #[expected_failure(abort_code = 5)]
    fun expired_tcard(account:&signer) acquires Store{
        dtcard_signup(account, 12);
        validate_dtcard(Signer::address_of(account));
    }
}
