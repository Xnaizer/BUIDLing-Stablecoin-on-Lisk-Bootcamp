// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
//Perintah pragma solidity ^0.8.19; dalam Solidity digunakan untuk menentukan versi yang digunakan untuk kompilasi kontrak pintar.
// Secara lebih rinci, pragma adalah sebuah direktif yang digunakan dalam banyak bahasa pemrograman, termasuk Solidity. Direktif ini memberi tahu kompilator bagaimana menangani kode tersebut. Dalam kasus Solidity, pragma digunakan untuk mendefinisikan versi kompilator yang akan digunakan.


// Di Solidity, kata kunci contract/ contract declaration digunakan untuk mendefinisikan sebuah kontrak pintar (smart contract). Kontrak ini berfungsi untuk mengatur logika dan interaksi dengan blockchain. Kontrak pintar adalah program yang dieksekusi di blockchain dan dapat berisi berbagai fungsi, variabel, dan struktur data yang berinteraksi dengan data di blockchain.

contract Danantiri {
    
    enum ProgramStatus { INACTIVE, REGISTERED, ALLOCATED }
    // enum (Enumeration) adalah tipe data yang memungkinkan kamu untuk mendefinisikan sekumpulan nilai yang terbatas dan terdefinisi. Dalam kasus ini, ProgramStatus adalah sebuah enum yang mendefinisikan status yang mungkin untuk suatu program
    
    // INACTIVE: Secara otomatis diberi nilai 0, yang biasanya menunjukkan bahwa program belum aktif atau terdaftar.

    // REGISTERED: Diberi nilai 1, yang menandakan bahwa program sudah terdaftar.

    // ALLOCATED: Diberi nilai 2, yang menunjukkan bahwa program telah dialokasikan (misalnya, dana atau sumber daya).


    struct Program {
        uint256 id;
        string name;
        uint256 target;
        string desc;
        address pic;
        ProgramStatus status;
        uint256 allocated;
    }
    // struct (singkatan dari structure) adalah tipe data buatan pengguna yang digunakan untuk mengelompokkan beberapa data menjadi satu unit. Jadi, daripada menyimpan banyak variabel terpisah yang saling berkaitan, kamu bisa menyatukannya dalam satu struct.

    struct History {
        uint256 timestamp;
        string history;
        uint256 amount;
    }



    address public owner;
    // owner
    // Menyimpan alamat wallet pemilik contract.
    // Biasanya dipakai untuk:
    // Akses khusus (admin-only)
    // Validasi siapa yang bisa nambah atau hapus program
    // Karena public, siapa pun bisa cek siapa owner lewat blockchain langsung.

    // constructor() {
    // owner = msg.sender; // orang yang deploy contract jadi owner
    // }


    Program[] public programs;
    // programs
    // Ini adalah array dinamis dari struct Program.

    // Menyimpan semua data program bantuan, penggalangan dana, atau kegiatan.

    // Karena public, kamu bisa baca tiap program dari luar contract, misalnya:
    // programs[0] akan kasih info program pertama.

    uint256 public totalManagedFund;
    // totalManagedFund
    // Menyimpan total dana yang masuk dan sedang dikelola oleh platform.
    // Bertambah saat ada user donasi atau dana masuk ke platform.
    // Bisa juga untuk transparansi di frontend (biar user tahu total dananya berapa).


    uint256 public totalAllocated;
    // totalAllocated
    // Menyimpan total dana yang sudah dialokasikan ke program.
    // Jadi, ini adalah bagian dari totalManagedFund yang sudah digunakan/dikirim untuk program tertentu.

    mapping (uint256 => History[]) public programHistories;
    // programHistories
    // Ini adalah mapping dari ID program (uint256) ke array riwayat (History[]).
    // Menyimpan semua histori transaksi atau aksi untuk setiap program.
    // Misal:
    // programHistories[0].push(History(block.timestamp, "Dana diterima", 1 ether));

    constructor() {
        owner = msg.sender; // constructor akan dipanggil sekali, dimana yang memiliki ini adalah yang mendeploy smart contract ini
    }

    modifier onlyAdmin() {
        require(msg.sender == owner, "Only Admin can call this function");
        // if (msg.sender != owner ){
        //     revert("Only Admin can call this function");
        // } // ini sama aja sebagai error handling
        
        _; // menyimpan pengecualian di bawah dan tidak ada error ketika pemanggilan fungsi ini diteruskan
    }

    // Apa itu modifier?
    // modifier itu seperti pengaman pintu masuk fungsi.
    // Dia akan ngecek dulu apakah syarat tertentu terpenuhi, baru fungsi boleh jalan.
    // Kalau syaratnya gagal, maka fungsi akan gagal juga / dibatalkan.

    modifier onlyPIC(uint256 _programId) {
        require(msg.sender == programs[_programId].pic, "Only PIC can call this function");
        _; // <-- artinya: lanjutkan ke isi fungsi setelah lolos pengecekan
    }

    event ProgramCreated(uint256 indexed programId, string name, uint256 target, address pic); // Digunakan saat program baru dibuat.
    event ProgramUpdated(uint256 indexed programId, string name, string desc, address pic); // Dipanggil saat informasi program diperbarui.
    event FundSent(address indexed sender, uint256 amount); //  Dicatat saat ada dana dikirim/donasi ke platform.
    event FundAllocated(uint256 indexed programId, uint256 amount); // Digunakan saat dana dialokasikan ke program.
    event FundWithdrawn(uint256 indexed  programId, address indexed pic, string history, uint256 amount); // Dicatat saat PIC menarik dana dari program.

    // event di Solidity dipakai untuk mencatat aktivitas ke blockchain log.
    // Frontend atau blockchain explorer (kayak Etherscan) bisa dengerin atau melihat event ini.

    // Kalau kamu menambahkan indexed ke dalam parameter event seperti ini:
    // event FundSent(address indexed sender, uint256 amount);
    // 📌 Parameter sender akan disimpan sebagai "indexed topic" dalam event log.
    // Dan ini bikin kamu bisa filter atau cari berdasarkan sender nanti di frontend atau blockchain explorer (seperti Etherscan).

    // Bayangin kamu punya buku catatan transaksi tanpa indexed:
    // ➤ "Ada 1000 transaksi, tapi kamu harus baca satu per satu untuk tahu siapa pengirimnya."

    // Tapi kalau kamu pakai indexed:
    // ✅ "Transaksi bisa dicari berdasarkan sender, tinggal ketik aja alamatnya. Lebih cepat dan efisien!"

    function createProgram(
        string calldata _name, // adalah parameter input yang dikirim dari frontend (luar kontrak) ke fungsi createProgram.
        uint256 _target,
        string calldata _desc,
        address _pic 
    ) external onlyAdmin {
        require(bytes(_name).length > 0, "Invalid name");
        require(_target > 0, "Invalid target");
        require(bytes(_desc).length > 0, "Invalid description");
        require(_pic != address(0), "Invalid PIC");

        // require di Solidity adalah fungsi untuk validasi atau pengecekan kondisi tertentu. Kalau kondisinya tidak terpenuhi, maka:
        // Eksekusi dihentikan (revert)
        // Sisa gas dikembalikan
        // Pesan error ditampilkan

        Program memory programData = Program({
            id: programs.length,
            name: _name,
            target: _target,
            desc: _desc,
            pic: _pic,
            status: ProgramStatus.REGISTERED,
            allocated: 0
        });
        // programs berasal dari Program[] public programs;

        programs.push(programData);
        emit ProgramCreated(programData.id, programData.name, programData.target, programData.pic);
        // emit di Solidity adalah keyword yang digunakan untuk memicu event agar tercatat di event log blockchain (Ethereum Virtual Machine log). Bisa dibilang, ini seperti membunyikan alarm untuk memberi tahu bahwa "eh, sesuatu baru saja terjadi di kontrak ini!"
    }


    function updateProgram(
        uint256 _programId, // ambil program id yang mau dirubah
        string calldata _name, // ubah namanya apa
        string calldata _desc, // ubah deksripsi menjadi apa
        address _pic // ubah addressnya kesiapa
    ) external onlyAdmin 
    {
        // require(_programId < programs.length, "Invalid program ID"); // jika id ga ada di program id maka invalid
        require(programs.length > 0, "No program exists"); // kita gunakan ini untuk lebih aman
        require(bytes(_name).length > 0, "Invalid name"); //nama harus ada huruf
        require(bytes(_desc).length > 0, "Invalid description"); // desc juga harus ada huruf 
        require(_pic != address(0), "Invalid PIC"); // klo addressnya kosong ga boleh

        Program storage program = programs[_programId]; // ambil data dengan tipe data Struct Program yang di simpan di programs array dengan id ini
        program.name = _name;
        program.desc = _desc;
        program.pic = _pic;  // update program yang ada menjadi yang di input

        emit ProgramUpdated(_programId, _name, _desc, _pic); // beritakan kalo ada perubahan ya
    }

    // Kata Kunci	        Tempat penyimpanan	                    Artinya

    // storage	            Blockchain (permanent)	                Data yang disimpan secara persisten dalam kontrak. Bisa dibaca dan ditulis.

    // memory	RAM         sementara (selama eksekusi fungsi)	    Data hanya hidup selama fungsi berjalan, setelah itu hilang.

    // calldata	        input external (read-only)	            Digunakan untuk parameter dari luar kontrak, tidak bisa diubah.


    function getAllProgram() external view returns (Program[] memory) {
        return programs;
    }


    
        
}


// 1. Interface

// interface IDarantiri {
//     function getData() external view returns (uint);
// }

// Sebuah interface digunakan untuk mendeklarasikan kontrak tanpa mengimplementasikan logika kontrak tersebut. Biasanya digunakan untuk mendefinisikan fungsi yang harus diimplementasikan oleh kontrak lain


// 2. Library

// library MathLib {
//     function add(uint a, uint b) public pure returns (uint) {
//         return a + b;
//     }
// }

// library adalah kontrak yang berisi fungsi-fungsi utilitas yang dapat dipanggil oleh kontrak lain. Biasanya, library digunakan untuk kode yang dapat digunakan kembali (reusable code) dan lebih efisien karena kode dalam library tidak memiliki state atau penyimpanan data.


// 3. Enum

// enum State { Active, Inactive, Closed }

// enum adalah tipe data yang memungkinkan kamu untuk mendefinisikan variabel dengan nilai yang terbatas dan terdefinisi. Ini membantu membuat kode lebih mudah dibaca dan dipahami.


// 4. Struct

// struct Person {
//     string name;
//     uint age;
// }

// struct adalah cara untuk mendefinisikan tipe data kompleks, yang bisa berisi beberapa variabel berbeda dalam satu entitas. Ini berguna untuk menyimpan data terkait dalam satu tempat.



// transfer ownership

// function transferOwnership(address newOwner) external onlyAdmin {
//     require(newOwner != address(0), "Invalid address");
//     owner = newOwner;
// }


// non aktif program

// function disableProgram(uint256 _programId) external onlyAdmin {
//     require(_programId < programs.length, "Invalid program ID");
//     programs[_programId].status = ProgramStatus.INACTIVE;
// }