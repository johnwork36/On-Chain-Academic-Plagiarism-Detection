# 🔍 On-Chain Academic Plagiarism Detection

A Clarity smart contract for detecting duplicate academic content submissions across educational institutions using blockchain technology.

## 📋 Features

- 🏫 **Institution Registration**: Educational institutions can register and get verified
- 📝 **Content Submission**: Submit academic content hashes with metadata
- 🚨 **Plagiarism Detection**: Check for duplicate submissions across all institutions
- 📊 **Institution Analytics**: Track submission counts and reputation scores
- 🔒 **Verification System**: Only verified institutions can submit content
- 📈 **Duplicate Tracking**: Monitor duplicate submission patterns

## 🚀 Getting Started

### Prerequisites

- Clarinet CLI installed
- Stacks blockchain environment

### Installation

```bash
git clone <repository-url>
cd On-Chain-Academic-Plagiarism-Detection
clarinet check
```

## 📚 Usage

### 1. Register an Institution 🏛️

```clarity
(contract-call? .On-Chain-Academic-Plagiarism-Detection register-institution "University Name")
```

### 2. Verify Institution (Contract Owner Only) ✅

```clarity
(contract-call? .On-Chain-Academic-Plagiarism-Detection verify-institution 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)
```

### 3. Submit Academic Content 📄

```clarity
(contract-call? .On-Chain-Academic-Plagiarism-Detection submit-content 
  0x1234567890abcdef1234567890abcdef12345678 
  "CS101" 
  "student123" 
  "assignment")
```

### 4. Check for Plagiarism 🔍

```clarity
(contract-call? .On-Chain-Academic-Plagiarism-Detection check-plagiarism 
  0x1234567890abcdef1234567890abcdef12345678)
```

## 🔧 Contract Functions

### Public Functions

| Function | Description | Parameters |
|----------|-------------|------------|
| `register-institution` | Register a new institution | `name: string-ascii 100` |
| `verify-institution` | Verify an institution (owner only) | `institution: principal` |
| `submit-content` | Submit content hash | `content-hash: buff 32, course-code: string-ascii 20, student-id: string-ascii 50, submission-type: string-ascii 20` |
| `update-contract-owner` | Update contract owner | `new-owner: principal` |

### Read-Only Functions

| Function | Description | Returns |
|----------|-------------|---------|
| `check-plagiarism` | Check if content exists | Submission details or not found |
| `get-submission-details` | Get submission information | Submission data |
| `get-institution-info` | Get institution details | Institution data |
| `get-total-submissions` | Get total submission count | uint |
| `get-total-institutions` | Get total institution count | uint |

## 🎯 How It Works

1. **Registration Phase** 📝
   - Institutions register with their name
   - Contract owner verifies legitimate institutions

2. **Content Submission** 📤
   - Verified institutions submit content hashes
   - Metadata includes course, student ID, and submission type
   - Timestamps and block heights are automatically recorded

3. **Plagiarism Detection** 🕵️
   - Check if content hash already exists
   - Get original submission details
   - Track duplicate submission patterns

4. **Analytics & Monitoring** 📊
   - Institution reputation scores
   - Submission and flagged content counts
   - Duplicate content tracking

## 🛡️ Security Features

- ✅ Only verified institutions can submit content
- ✅ Contract owner controls institution verification
- ✅ Immutable submission records
- ✅ Automatic duplicate detection
- ✅ Reputation scoring system

## 🔒 Error Codes

- `u100`: Unauthorized access
- `u101`: Already exists
- `u102`: Not found
- `u103`: Invalid institution
- `u104`: Invalid hash

## 🧪 Testing

```bash
clarinet test
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## 📄 License

This project is licensed under the MIT License.

## 🌟 Future Enhancements

- 🔄 Content similarity scoring
- 📊 Advanced analytics dashboard
- 🔗 Integration with existing LMS systems
- 🌐 Multi-chain support
- 📱 Mobile application interface
