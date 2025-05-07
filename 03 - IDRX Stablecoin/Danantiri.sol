// SPDX-License-Identifier: MIT
// SPDX (Software Package Data Exchange) adalah standar untuk menyatakan informasi lisensi secara ringkas dalam file sumber kode.
// Massachusetts Institute of Technology License adalah lisensi yang sangat permisif, berarti orang dapat menggunakan ulang dan memodifikasi kode ini bahkan untuk keperluan komersial asalkan mencantumkan kredit kepada pembuat asli

pragma solidity ^0.8.0; // ini digunakan untuk menentukan versi solidity yang akan digunakan karna setiap versi memiliki fitur update yang memungkinkan terjadinya perubahan pada kode yang digunakan 

interface IERC20 {  // ini berfungsi sebagai jembatan kontrak untuk berinteraksi dengan token ERC20(IDRX) yang sudah di deploy di tempat lain.
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool); // Mengambil token dari alamat lain (harus ada izin approve dulu).
    function transfer(address recipient, uint256 amount) external returns (bool); // Mengirim token ke alamat lain.
    function balanceOf(address account) external view returns (uint256); // Mengecek saldo token dari suatu alamat.
}

contract Danantiri { // ini adalah pendeklarasian pembuatan smart contract danantiri, seperti pembuatan class namun ini contrct
    enum ProgramStatus { INACTIVE, REGISTERED, ALLOCATED } 
    // enum ini akan digunakan sebagai status dari yang awalnya angka diubah menjadi nama

    struct Program {
        // ini adalah pendeklarasian suatu entitas program yang memiliki komponen sesuai  yang ada dibawah, dimana program nantinya harus memiliki semua identity yang ada disini dan harus bertipe data yang sama sesuai yang dideklarasikan
        uint256 id;
        string name;
        uint256 target;
        string desc;
        address pic;
        ProgramStatus status;
        uint256 allocated;
    }

    struct History {
        // ini adalah struktur untuk data history nantinya
        uint256 timestamp;
        string history;
        uint256 amount;
    }
    // ========================================================
    address public owner; // tipe data adalah addres, dapat diakses dari luar yang nanti cuma bisa dipanggil oleh owner itu sendiri
    Program[] public programs; // tipe data programs nantinya akan berisi array dari struct Program yang ada di atas, dan programs nantinya dapat dilihat oleh siapapun karna public
    uint256 public totalManagedFund; // ini akan berisi total fund yang dimanage
    uint256 public totalAllocated; // ini akan berisi total fund yang di alokasikan ke program pic
    IERC20 public idrxToken; // ini kita nantinya akan mengambil token idrx dengan referensi kontrak yang ada di idrxToken
    mapping(uint256 => History[]) public programHistories;
    // ini adalah pendeklarasian variable yang ada di kontrak digunakan nantinya untuk menyimpan data penting secara permanen di blockchain.
    // ========================================================

    // ========================================================
    // Dipanggil saat program baru dibuat
    event ProgramCreated(
        uint256 indexed programId,  // ID unik program
        string name,                // Nama program
        uint256 target,             // Target dana
        address pic                 // Penanggung jawab program
    );

    // Dipanggil saat data program diperbarui
    event ProgramUpdated(
        uint256 indexed programId,  // ID program yang diupdate
        string name,                // Nama baru
        string desc,                // Deskripsi baru
        address pic                 // PIC baru
    );

    // Dipanggil saat donatur mengirimkan dana
    event FundSent(
        address indexed sender,     // Alamat pengirim dana
        uint256 amount              // Jumlah dana dikirim
    );

    // Dipanggil saat dana dialokasikan ke program tertentu
    event FundAllocated(
        uint256 indexed programId,  // ID program
        uint256 amount              // Jumlah dana yang dialokasikan
    );

    // Dipanggil saat PIC menarik dana dari program
    event FundWithdrawn(
        uint256 indexed programId,  // ID program
        address indexed pic,        // PIC yang menarik dana
        string history,             // Keterangan penarikan
        uint256 amount              // Jumlah dana yang ditarik
    );

    // ========================================================

    modifier onlyAdmin() {
        // Memastikan bahwa pengirim transaksi (msg.sender) adalah admin (pemilik kontrak)
        require(msg.sender == owner, "Only admin can call this function");
        _;  // Menandakan bahwa fungsi yang menggunakan modifier ini akan dijalankan setelah pengecekan selesai
    }

    modifier onlyPIC(uint256 _programId) {
        // Memastikan bahwa pengirim transaksi (msg.sender) adalah PIC dari program yang ditentukan oleh _programId
        require(msg.sender == programs[_programId].pic, "Not PIC of this program");
        _;  // Menandakan bahwa fungsi yang menggunakan modifier ini akan dijalankan setelah pengecekan selesai
    }

    constructor(address _tokenAddress) {
        require(_tokenAddress != address(0), "Invalid token address");  // Memastikan alamat token bukan address kosong
        owner = msg.sender;  // Mengatur pemilik kontrak (admin) menjadi pengirim transaksi
        idrxToken = IERC20(_tokenAddress);  // Menyimpan alamat kontrak token IDRX sebagai instance dari IERC20
    }

    function createProgram(
        string calldata _name,      // Nama program yang akan dibuat
        uint256 _target,            // Target dana yang diperlukan (dalam token)
        string calldata _desc,      // Deskripsi program
        address _pic                // Alamat orang yang bertanggung jawab (PIC)
    )
        external            // external ini adalah fungsi yang ingin dipanggil dari luar kotrak jadi bukan dri dalam smartcontract nantinya, dimana orang yang dapat menggamilnya adalah si onlyAdmin()

        onlyAdmin
        
    {
        require(bytes(_name).length > 0, "Program name cannot be empty");    // Memastikan nama program tidak kosong
        require(_target > 0, "Target must be greater than zero");             // Memastikan target dana lebih besar dari nol
        require(bytes(_desc).length > 0, "Description cannot be empty");    // Memastikan deskripsi tidak kosong
        require(_pic != address(0), "PIC address cannot be zero");           // Memastikan alamat PIC valid (tidak address(0))

        uint256 newId = programs.length;  // Menentukan ID unik untuk program baru (berdasarkan panjang array 'programs')

        // Membuat objek Program baru dengan parameter yang diterima
        Program memory newProgram = Program({
            id: newId,            // ID program baru
            name: _name,          // Nama program
            target: _target,      // Target dana
            desc: _desc,          // Deskripsi program
            pic: _pic,            // Alamat PIC
            status: ProgramStatus.REGISTERED, // Status program (baru dibuat, status 'REGISTERED')
            allocated: 0          // Alokasi dana dimulai dengan 0
        });

        programs.push(newProgram);  // Menambahkan program baru ke dalam array 'programs'
        
        emit ProgramCreated(newId, _name, _target, _pic);  // Memicu event 'ProgramCreated' dengan detail program yang baru dibuat
    }


    function updateProgram(
        uint256 _programId,                  // Parameter untuk ID program yang ingin diperbarui
        string calldata _name,               // Parameter untuk nama program baru
        string calldata _desc,               // Parameter untuk deskripsi program baru
        address _pic                         // Parameter untuk alamat PIC (Person In Charge) baru
    )
        external                              // Fungsi ini hanya bisa dipanggil dari luar kontrak
        onlyAdmin                             // Hanya admin (pemilik kontrak) yang dapat memanggil fungsi ini
    {
        // Pengecekan bahwa status program harus REGISTERED agar bisa diperbarui
        require(programs[_programId].status == ProgramStatus.REGISTERED, "Program is not registered");

        // Pengecekan bahwa nama program tidak boleh kosong
        require(bytes(_name).length > 0, "Program name cannot be empty");

        // Pengecekan bahwa deskripsi program tidak boleh kosong
        require(bytes(_desc).length > 0, "Description cannot be empty");

        // Pengecekan bahwa alamat PIC tidak boleh address(0)
        require(_pic != address(0), "PIC address cannot be zero");

        // Mengambil data program yang akan diperbarui dari array programs menggunakan ID program yang diberikan
        Program storage program = programs[_programId];

        // Memperbarui nilai-nilai dalam struktur Program dengan nilai-nilai baru
        program.name = _name;    // Mengupdate nama program
        program.desc = _desc;    // Mengupdate deskripsi program
        program.pic = _pic;      // Mengupdate alamat PIC program

        // Memancarkan event ProgramUpdated untuk memberitahukan perubahan data program
        emit ProgramUpdated(_programId, _name, _desc, _pic);
    }


    function sendFund(uint256 amount) external {
        // Mengecek bahwa jumlah dana yang dikirim lebih besar dari 0
        require(amount > 0, "Amount must be greater than zero");

        // Menggunakan fungsi transferFrom dari ERC20 untuk mentransfer token dari pengirim (msg.sender) ke kontrak ini (address(this))
        // Pastikan bahwa pengirim telah memberikan izin untuk mentransfer token sebelumnya
        require(idrxToken.transferFrom(msg.sender, address(this), amount), "Token transfer failed");

        // Menambahkan jumlah dana yang berhasil dikelola (totalManagedFund) dengan jumlah dana yang baru diterima
        totalManagedFund += amount;

        // Memancarkan event FundSent untuk memberitahukan bahwa dana telah berhasil dikirim
        emit FundSent(msg.sender, amount);
    }

    function allocateFund(uint256 _programId) external onlyAdmin {
        // Mengambil data program yang sesuai dengan _programId dari array 'programs'
        Program storage program = programs[_programId];

        // Mengecek apakah status program adalah REGISTERED, sehingga dapat dialokasikan dana
        require(program.status == ProgramStatus.REGISTERED, "Program is not registered");

        // Menghitung dana yang tersedia untuk dialokasikan (saldo kontrak dikurangi dana yang sudah dialokasikan)
        uint256 available = idrxToken.balanceOf(address(this)) - totalAllocated;
        
        // Memastikan dana yang tersedia cukup untuk memenuhi target program
        require(available >= program.target, "Allocation must be equal to program target");

        // Menambahkan dana yang dialokasikan untuk program dan memperbarui total dana yang dialokasikan
        program.allocated += program.target;
        totalAllocated += program.target;

        // Mengubah status program menjadi ALLOCATED setelah dana berhasil dialokasikan
        program.status = ProgramStatus.ALLOCATED;

        // Memancarkan event FundAllocated untuk memberitahukan bahwa dana telah berhasil dialokasikan
        emit FundAllocated(_programId, program.target);
    }


    function withdrawFund(uint256 _programId, string calldata _history, uint256 _amount) external onlyPIC(_programId) {
        // Mengambil data program yang sesuai dengan _programId dari array 'programs'
        Program storage program = programs[_programId];

        // Mengecek apakah status program adalah ALLOCATED, sehingga dana dapat ditarik
        require(program.status == ProgramStatus.ALLOCATED, "Program is not allocated");

        // Memastikan bahwa deskripsi history tidak kosong
        require(bytes(_history).length > 0, "History cannot be empty");

        // Memastikan bahwa jumlah yang ingin ditarik lebih besar dari nol
        require(_amount > 0, "Amount must be greater than zero");

        // Memastikan jumlah yang ingin ditarik tidak melebihi dana yang dialokasikan untuk program
        require(_amount <= program.allocated, "Amount to withdraw exceeds allocated fund");

        // Mengurangi dana yang dialokasikan untuk program dengan jumlah yang ditarik
        program.allocated -= _amount;
        totalAllocated -= _amount;

        // Menyimpan riwayat penarikan dana dengan detail waktu, deskripsi, dan jumlah yang ditarik
        programHistories[_programId].push(History({
            timestamp: block.timestamp,
            history: _history,
            amount: _amount
        }));

        // Mentransfer token dari kontrak ke alamat pemanggil (PIC)
        require(idrxToken.transfer(msg.sender, _amount), "Token transfer failed");

        // Memancarkan event FundWithdrawn untuk memberitahukan bahwa dana telah berhasil ditarik
        emit FundWithdrawn(_programId, msg.sender, _history, _amount);
    }


    // Fungsi untuk mendapatkan seluruh daftar program yang ada dalam kontrak
    function getAllProgram() external view returns (Program[] memory) {
        // Mengembalikan seluruh array 'programs' yang berisi data semua program
        return programs;
    }

    // Fungsi untuk mendapatkan riwayat penarikan dana untuk program tertentu
    function getProgramHistory(uint256 _programId) external view returns (History[] memory) {
        // Mengembalikan riwayat penarikan dana yang disimpan untuk program yang sesuai dengan _programId
        return programHistories[_programId];
    }
}
