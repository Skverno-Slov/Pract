using CommunityToolkit.Mvvm.Input;
using Signal.Server.Data.Dtos;
using Signal.Services;
using System.Collections.ObjectModel;
using System.Threading.Tasks;

namespace Signal.ViewModels
{
    public partial class UsersPageViewModel : ViewModelBase
    {
        public ObservableCollection<UserDto> Users { get; } = new();

        [RelayCommand]
        async Task UpdateDataAsync()
        {
            await ApiService.Instance.GetUsersAsync();
        }

        [RelayCommand]
        void OpenDetail()
        {

        }
    }
}
