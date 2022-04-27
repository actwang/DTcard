module NamedAddr::DTCard {

    use Std::Signer;

    /// Address and id of the admin user
    const ADMIN_ACCOUNT: address = @NamedAddr;
    const ADMIN_ID:u64 = 0;

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

    /*
        Function for dtcard signups, every user has the authority
        account: the signer of the user ready to signup
        id: the student or admin 's id for signup
    */
    public fun dtcard_signup(account: &signer, id: u64) {

        // Abort if the user has already signed up a DTCard, not matter whether it is issued
        assert!(!exists<Store>(Signer::address_of(account)), EALREADY_HAS_DTCARD);

        // Instantiate an empty unissued tcard using the user's id 
        let empty_dtcard = DTCard { student_id: id, expiry_date: 0, issued: false };

        // Create a DTCard holder to hold the DTCard
        let dtcard_holder = Store { dtcard: empty_dtcard };

        //  Move the DTCard under the user's address, now user own this resource
        move_to<Store>(account, dtcard_holder)
    }

    // Move prover for function dtcard_signup
    spec dtcard_signup {
        pragma aborts_if_is_strict;
        // Abort if the user has already signed up a DTCard, not matter whether it is issued
        aborts_if exists<Store>(Signer::address_of(account));

        let post student_id = global<Store>(Signer::address_of(account)).dtcard.student_id;
        let post expiry_date = global<Store>(Signer::address_of(account)).dtcard.expiry_date;
        let post issued = global<Store>(Signer::address_of(account)).dtcard.issued;

        // Ensure correct signup by matching the infos
        ensures student_id == id;
        ensures expiry_date == 0;
        ensures issued == false;
        ensures exists<Store>(Signer::address_of(account));
    }

    /*
        Function for the issue of a signed up DTCard, only the admin user has the authority
        admin_account: the signer of the user expected to be the admin user
        student_address: the address of the user who is expected to own the DTCard to be issued
    */
    public fun issue_DTCard(admin_account: &signer, student_address:address) acquires Store {
        
        // Abort if a non-admin user tries to issue the DTCard
        assert!(Signer::address_of(admin_account) == ADMIN_ACCOUNT, ENOT_ADMIN_ACCOUNT);
        // Abort if there is no DTCard under the user's address
        assert!(exists<Store>(student_address), EDTCARD_NOT_SIGNUP);

        let dtcard_ref = &mut borrow_global_mut<Store>(student_address).dtcard;

        // Abort if the DTCard of the user is already issued
        assert!(dtcard_ref.issued==false, EALREADY_ISSUED);

        // Issue the DTCard
        dtcard_ref.issued = true;
        dtcard_ref.expiry_date = 1713240000;

    }

    spec issue_DTCard {
        pragma aborts_if_is_strict;
        // Abort if a non-admin user tries to issue the DTCard
        aborts_if Signer::address_of(admin_account) != ADMIN_ACCOUNT;
        // Abort if there is no DTCard under the user's address
        aborts_if !exists<Store>(student_address);

        let empty_card_issued = global<Store>(student_address).dtcard.issued;
        // Abort if the DTCard of the user is already issued
        aborts_if empty_card_issued == false;

        let post issued = global<Store>(student_address).dtcard.issued;
        let post expiry_date = global<Store>(student_address).dtcard.expiry_date;

        // Ensure correct issue by matching the infos
        ensures issued == true;
        ensures expiry_date == 1713240000;
    }

    /*
        Function for the validation of an issued DTCard, every user has the authority
        addr: the address of the owner of the DTCard
    */
    public fun validate_dtcard(addr: address) acquires Store {
        // Abort if there is no DTCard under the user's address
        assert!(exists<Store>(addr), EDTCARD_NOT_EXIST);

        let student_card = &borrow_global<Store>(addr).dtcard;

        // Abort if the DTCard is not issued
        assert!(student_card.issued == true, EDTCARD_NOT_VALID);

    } 

    spec validate_dtcard {
        pragma aborts_if_is_strict;

        // Abort if there is no DTCard under the user's address
        aborts_if !exists<Store>(addr);

        let student_card_issued = global<Store>(addr).dtcard.issued;

        // Abort if the DTCard is not issued
        aborts_if student_card_issued == false;
    }

    // Test where admin signup, issues_DTCard to themselves and verify the validity 
    #[test(account = @NamedAddr)]
    fun happy_admin(account: &signer) acquires Store {
        let addr = Signer::address_of(account);

        dtcard_signup(account, ADMIN_ID);

        issue_DTCard(account, addr);
        
        validate_dtcard(addr);
    }

    // Test where admin tries to issue DTCard, but the student did not sign up (resource is not initialised)
    #[test(admin_account = @NamedAddr, student_address = @0xCA)]
    #[expected_failure(abort_code = 2)]
    fun not_intialized(admin_account: &signer, student_address:address) acquires Store {
        issue_DTCard(admin_account, student_address);
    }

    // Test where DTCard is already issued to that address, cannot issue again
    #[test(admin_account = @NamedAddr, student_account = @0xCB)]
    #[expected_failure(abort_code = 3)]
    fun already_issued(admin_account: &signer, student_account: &signer) acquires Store {
        let student_id = 5192;

        let student_address = Signer::address_of(student_account);

        dtcard_signup(student_account, student_id);

        issue_DTCard(admin_account, student_address);

        issue_DTCard(admin_account, student_address);
    }

    // Test where non-admin tries to issue DTCard
    #[test(account = @0xCC)]
    #[expected_failure(abort_code = 0)]
    fun no_access(account: &signer) acquires Store {
        let addr = Signer::address_of(account);

        dtcard_signup(account, ADMIN_ID);

        issue_DTCard(account, addr);
    }

    // Test where DTCard issued to a student after signup
    #[test(admin_account = @NamedAddr, student_account = @0xCD)]
    fun happy_student(admin_account: &signer, student_account: &signer) acquires Store {
        let student_id = 5193;

        let student_address = Signer::address_of(student_account);

        dtcard_signup(student_account, student_id);

        issue_DTCard(admin_account, student_address);

    }

    // Test where it should abort when trying to authenticate an invalid DTCard
    #[test(account=@0xCDD)]
    #[expected_failure(abort_code = 4)]
    fun invalid_tcard(account: &signer) acquires Store{
        validate_dtcard(Signer::address_of(account));
    }

    // Test where there is a DTCard resource at address but is not issued
    //      resource expiry and issued not set
    #[test(account = @0xCAD)]
    #[expected_failure(abort_code = 5)]
    fun expired_tcard(account:&signer) acquires Store{
        dtcard_signup(account, 10017878);
        validate_dtcard(Signer::address_of(account));
    }


}
